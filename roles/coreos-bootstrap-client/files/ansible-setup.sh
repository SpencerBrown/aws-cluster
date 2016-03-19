#!/usr/bin/env bash

function got_error() {
  echo "Error encountered in ansible NFS setup script -- line $1"
  exit 3
}

trap 'got_error ${LINENO}' ERR

if [ ! -f /opt/bin/pypy/bin/pypy ]; then

  mkdir -p /var/cluster-bin
  systemctl start rpc-statd
  mount 172.2.0.20:/opt/bin /var/cluster-bin
  mkdir -p /opt/bin
  cd /opt/bin
  cp -R /var/cluster-bin/pypy/ /opt/bin/

else
  exit 1

fi

