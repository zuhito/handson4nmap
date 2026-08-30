#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/pnet-start.sh
sleep 8

nmap --script ./external/multicast-profinet-discovery.nse | tee /tmp/pnet.txt
grep -q "vendorValue: P-Net Sample Application" /tmp/pnet.txt
grep -q "nameOfStation: aic-pnet-01" /tmp/pnet.txt
grep -q "deviceRole: 0x01 (IO-Device)" /tmp/pnet.txt
grep -q "ip_info: IP set" /tmp/pnet.txt

pkill -x pn_dev || true
sleep 2
