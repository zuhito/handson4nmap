#!/bin/bash
set -e
cd "$(dirname "$0")/.."

rm -rf work/busybox
git clone -q --depth 1 --branch 1_36_1 https://github.com/mirror/busybox.git work/busybox
cd work/busybox
make allnoconfig > /dev/null
sed -i 's/# CONFIG_NTPD is not set/CONFIG_NTPD=y/' .config
sed -i 's/# CONFIG_FEATURE_NTPD_SERVER is not set/CONFIG_FEATURE_NTPD_SERVER=y/' .config
sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
yes "" | make oldconfig > /dev/null
make -j "$(nproc)" > /dev/null
