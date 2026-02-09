#!/bin/bash
set -e

./compile.sh build \
  BOARD=orangepi-4pro \
  BRANCH=mainline \
  BUILD_MINIMAL=yes \
  KERNEL_CONFIGURE=no \
  RELEASE=bookworm \
  SKIP_EXTERNAL_DRIVERS=yes
