#!/usr/bin/env bash

function got_error() {
  echo "Error encountered in ansible NFS setup script -- line $1"
  exit 3
}

trap 'got_error ${LINENO}' ERR

if [ ! -f /opt/bin/pypy/bin/pypy ]; then

  mkdir -p /var/cluster_bin
  mount 172.20.0.20:/opt/bin /var/cluster_bin
  mkdir -p /opt/bin
  cp -R /var/cluster_bin/pypy/ /opt/bin/

else
  exit 1

fi

