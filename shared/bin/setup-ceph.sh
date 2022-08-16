#!/bin/bash

set -e

cd /ceph
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

git config --global --add safe.directory '*'

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
