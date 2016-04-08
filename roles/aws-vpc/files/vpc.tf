provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_iam_role" "master_role" {
  name = "${var.env}"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "master_policy" {
  name = "${var.env}"
  role = "${aws_iam_role.master_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["elasticloadbalancing:*"],
      "Resource": ["*"]
    },
    {
      "Effect": "Allow",
      "Action": ["s3:*"],
      "Resource": ["*"]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "master_profile" {
  name = "${var.env}"
  roles = ["${aws_iam_role.master_role.name}"]
}


resource "aws_vpc" "cluster_vpc" {
  cidr_block = "${var.cluster_ip_prefix}.0.0/16"
  enable_dns_hostnames = true
  tags {
    Name = "${var.env}"
    KubernetesCluster = "${var.env}"
  }
}

resource "aws_subnet" "cluster_subnet_public" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${var.aws_zone}"
  cidr_block = "${var.cluster_ip_prefix}.0.0/24"
  tags {
    Name = "${var.env}-cluster-public"
    # do NOT add KubernetesCluster tag here, as Kubernetes uses tag to find "the" subnet where cluster nodes reside
  }
}

resource "aws_subnet" "cluster_subnet_private" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${var.aws_zone}"
  cidr_block = "${var.cluster_ip_prefix}.1.0/24"
  tags {
    Name = "${var.env}-cluster-private"
    KubernetesCluster = "${var.env}"
  }
}

resource "aws_internet_gateway" "cluster_internet_gateway" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  tags {
    Name = "${var.env}-cluster"
    KubernetesCluster = "${var.env}"
  }
}

resource "aws_eip" "cluster_nat" {
  vpc = true
}

resource "aws_nat_gateway" "cluster_nat" {
  subnet_id = "${aws_subnet.cluster_subnet_public.id}"
  allocation_id = "${aws_eip.cluster_nat.id}"
  depends_on = ["aws_internet_gateway.cluster_internet_gateway"]
}

resource "aws_security_group" "cluster_security_group_public" {
  name = "cluster_security_group_public"
  description = "Public SG: allow ssh and http/https"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  tags {
    Name = "${var.env}-cluster-public"
    # do NOT add clusterrnetsCluster tag here, on purpose
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = "${var.cluster_ssh_port}"
    to_port = "${var.cluster_ssh_port}"
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "${aws_vpc.cluster_vpc.cidr_block}",
      "${var.cluster_pod_cidr}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group" "cluster_proxy" {
  name = "cluster_security_group_proxy"
  description = "Proxy SG: allow http/https"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  tags {
    Name = "${var.env}-cluster-proxy"
    # do NOT add clusterrnetsCluster tag here, on purpose
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${aws_vpc.cluster_vpc.cidr_block}"]
  }
}

resource "aws_security_group" "cluster_security_group_private" {
  name = "cluster_security_group_private"
  description = "Private SG: allow all traffic from our VPC"
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  tags {
    Name = "${var.env}-cluster-private"
    KubernetesCluster = "${var.env}"
  }
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "${aws_vpc.cluster_vpc.cidr_block}",
      "${var.cluster_pod_cidr}"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_route_table" "cluster_route_table_private"
{
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  tags {
    Name = "${var.env}-cluster-private"
    KubernetesCluster = "${var.env}"
  }
}

resource "aws_route" "nat_gateway" {
  route_table_id = "${aws_route_table.cluster_route_table_private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.cluster_nat.id}"
}

resource "aws_route_table" "cluster_route_table_public"
{
  vpc_id = "${aws_vpc.cluster_vpc.id}"
  tags {
    Name = "${var.env}-cluster-public"
    // do NOT put a KubernetesCluster tag here, so Kubernetes doesn't mess with it
  }
}

resource "aws_route" "internet_gateway" {
  route_table_id = "${aws_route_table.cluster_route_table_public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.cluster_internet_gateway.id}"
}

resource "aws_route_table_association" "cluster_route_table_association_public" {
  subnet_id = "${aws_subnet.cluster_subnet_public.id}"
  route_table_id = "${aws_route_table.cluster_route_table_public.id}"
}

resource "aws_route_table_association" "cluster_route_table_association_private" {
  subnet_id = "${aws_subnet.cluster_subnet_private.id}"
  route_table_id = "${aws_route_table.cluster_route_table_private.id}"
}



