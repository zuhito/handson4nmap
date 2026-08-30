#!/bin/bash
set -e
cd "$(dirname "$0")/.."

NMAP_TAG="${NMAP_TAG:-v7.991}"
rm -rf external/nmap
git clone -q --branch "$NMAP_TAG" --depth 1 https://github.com/nmap/nmap.git external/nmap
cd external/nmap
./configure --without-zenmap --without-ndiff --without-nping --without-ncat --with-libssh2=no
make -j "$(nproc)"
make install
