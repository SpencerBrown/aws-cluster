#!/usr/bin/env bash

PYPY_VERSION=$1

function got_error() {
  echo "Error encountered in ansible setup script -- line $1"
  exit 3
}

trap 'got_error ${LINENO}' ERR

if [ ! -f /opt/bin/pypy/bin/pypy ]; then

  mkdir -p /opt/bin
  cd /opt/bin
  wget https://bitbucket.org/squeaky/portable-pypy/downloads/pypy-${PYPY_VERSION}-linux_x86_64-portable.tar.bz2
  tar -jxf pypy-${PYPY_VERSION}-linux_x86_64-portable.tar.bz2
  rm pypy-${PYPY_VERSION}-linux_x86_64-portable.tar.bz2
  mv pypy-${PYPY_VERSION}-linux_x86_64-portable pypy

else
  exit 1

fi

if [ ! -f /opt/bin/get-pip.py ]; then

  wget https://bootstrap.pypa.io/get-pip.py
  pypy/bin/pypy get-pip.py
  rm get-pip.py

else
  exit 2

fi

