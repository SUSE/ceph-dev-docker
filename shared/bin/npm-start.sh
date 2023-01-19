#!/bin/bash

VERSION="${VERSION:-master}"

set -e

setup-proxy.sh

cd /ceph/src/pybind/mgr/dashboard/frontend

case "$VERSION" in
"mimic" | "nautilus" | "octopus" | "pacific")
  source /ceph/build/src/pybind/mgr/dashboard/node-env/bin/activate
  ;;
*)
  source /ceph/build/src/pybind/mgr/dashboard/frontend/node-env/bin/activate
  ;;
esac

npm ci --unsafe-perm

npm start -- --disableHostCheck=true
