#!/bin/bash

set -e

cd /ceph

# Make sure the PIP RPM package is uninstalled and install/upgrade
# the tool manually. This is done because it is not possible to upgrade
# PIP to the latest version if it was installed via the system package
# manager.
# The command line `python3 -m pip install --upgrade pip` will not
# work anymore because it will fail while uninstalling the Python
# packages.
zypper -n rm python3-pip || true
curl -sSL https://bootstrap.pypa.io/get-pip.py | python3 -

find . -name \*.pyc -delete
./install-deps.sh

ARGS="-DENABLE_GIT_VERSION=OFF -DWITH_TESTS=ON -DWITH_CCACHE=ON $ARGS"
ARGS="-DWITH_PYTHON3=3 -DWITH_RADOSGW_AMQP_ENDPOINT=OFF -DWITH_RADOSGW_KAFKA_ENDPOINT=OFF $ARGS"

NPROC=${NPROC:-$(nproc --ignore=2)}

# Other dependencies
zypper -n install utf8proc-devel

# SSO dependencies
zypper -n install libxmlsec1-1 libxmlsec1-nss1 libxmlsec1-openssl1 xmlsec1-devel xmlsec1-openssl-devel
pip install python3-saml

if [ "$CLEAN" == "true" ]; then
    echo "CLEAN INSTALL"
    git clean -fdx
fi

if [ -d "build" ]; then
    git submodule update --init --recursive
    cd build
    cmake -DBOOST_J=$NPROC $ARGS ..
else
    ./do_cmake.sh $ARGS
    cd build
fi

if which ninja; then
    ninja -j$NPROC
else
    ccache make -j$NPROC
fi
