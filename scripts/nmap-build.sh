#!/bin/bash
set -e
cd "$(dirname "$0")/.."

NMAP_VERSION="${NMAP_VERSION:-7.98}"

rm -rf work/nmap
mkdir -p work
tar -xjf "scripts/nmap-${NMAP_VERSION}.tar.bz2" -C work
mv "work/nmap-${NMAP_VERSION}" work/nmap
cd work/nmap

sed -i 's/^dependencies = {/dependencies = {\n  "opcua",/' scripts/clock-skew.nse

./configure --without-zenmap --without-ndiff --without-nping --without-ncat --with-libssh2=no
make -j "$(nproc)"
make install
