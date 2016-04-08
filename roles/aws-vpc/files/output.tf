# Output variables that Ansible needs to provision the nodes.
# They are output in the form "name = value"

output "cluster_vpc_id" {value = "${aws_vpc.cluster_vpc.id}"}
output "cluster_subnet_public_id" {value = "${aws_subnet.cluster_subnet_public.id}"}
output "cluster_subnet_private_id" {value = "${aws_subnet.cluster_subnet_private.id}"}
output "cluster_sg_public_id" {value = "${aws_security_group.cluster_security_group_public.id}"}
output "cluster_sg_private_id" {value = "${aws_security_group.cluster_security_group_private.id}"}