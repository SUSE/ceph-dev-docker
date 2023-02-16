#!/bin/bash

set -e

# python3-asyncssh
zypper addrepo https://download.opensuse.org/repositories/devel:/languages:/python:/backports/15.3/devel:languages:python:backports.repo || true
zypper --gpg-auto-import-keys refresh
zypper -n install python3-asyncssh
# Immediately remove the repository, otherwise already installed
# Python packages will be upgraded from this repo which will break
# the installation because the dependencies of various packages are
# not correct.
zypper removerepo devel_languages_python_backports

# libthrift
zypper addrepo https://download.opensuse.org/repositories/devel:/tools/SLE_15_SP3/devel:tools.repo || true
zypper --gpg-auto-import-keys ref

# Install missing gcc11 packages (GCC > 8.1+ required due to C++17
# requirements)
zypper -n install gcc11-c++

cd /ceph
find . -name \*.pyc -delete
./install-deps.sh

ARGS="-DENABLE_GIT_VERSION=OFF -DWITH_TESTS=ON -DWITH_CCACHE=ON $ARGS"
ARGS="-DWITH_PYTHON3=3 -DWITH_RADOSGW_AMQP_ENDPOINT=OFF -DWITH_RADOSGW_KAFKA_ENDPOINT=OFF $ARGS"
ARGS="-DCMAKE_C_COMPILER=gcc-11 -DCMAKE_CXX_COMPILER=g++-11 $ARGS"

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
