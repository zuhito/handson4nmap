#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# The container image ships an nmap that predates multicast-profinet-discovery,
# so the release archive kept in scripts/ is built and installed to /usr/local.
NMAP_VERSION="${NMAP_VERSION:-7.98}"

rm -rf work/nmap
mkdir -p work
tar -xjf "scripts/nmap-${NMAP_VERSION}.tar.bz2" -C work
mv "work/nmap-${NMAP_VERSION}" work/nmap
cd work/nmap

# clock-skew only runs after the scripts listed in its dependencies, so opcua.nse
# has to be declared there for its timestamps to be aggregated.
sed -i 's/^dependencies = {/dependencies = {\n  "opcua",/' scripts/clock-skew.nse

./configure --without-zenmap --without-ndiff --without-nping --without-ncat --with-libssh2=no
make -j "$(nproc)"
make install
