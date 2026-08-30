#!/bin/bash
set -e
cd "$(dirname "$0")/.."

IFACE="${PROFINET_IFACE:-eth0}"
mkdir -p external/p-net/store

for pid in $(pgrep -x python3); do
  tr '\0' ' ' < "/proc/$pid/cmdline" | grep -q profinet-server && kill -9 "$pid" || true
done
pgrep -x pn_dev > /dev/null && pkill -x pn_dev || true
sleep 2

cd external/p-net/build
setsid nohup ./pn_dev -i "$IFACE" -s aic-pnet-01 -p ../store < /dev/null > /tmp/pnet.log 2>&1 &
