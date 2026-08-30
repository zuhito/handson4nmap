#!/bin/bash
set -e
cd "$(dirname "$0")/.."

for pid in $(pgrep -x python3); do
  tr '\0' ' ' < /proc/$pid/cmdline | grep -q profinet-server && kill -9 "$pid" || true
done
sleep 2
setsid nohup python3 "$1" < /dev/null > /tmp/profinet.log 2>&1 &
sleep 8

nmap --script multicast-profinet-discovery | tee /tmp/profinet.txt
grep -q "vendorValue: Aichi Company AIC-PLC-01" /tmp/profinet.txt
grep -q "nameOfStation: aic-plc-01" /tmp/profinet.txt
grep -q "deviceRole: 0x02 (IO-Controller)" /tmp/profinet.txt
grep -q "ip_info: IP set" /tmp/profinet.txt
