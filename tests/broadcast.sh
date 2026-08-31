#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# Both scripts need a second host on the link, which scripts/dhcp-start.sh
# provides through a veth pair and a network namespace.
bash scripts/dhcp-start.sh

nmap --script broadcast-wake-on-lan \
  --script-args broadcast-wake-on-lan.MAC=02:fc:00:00:00:01 | tee /tmp/wol.txt
grep -q "Sent WOL packet to: 02:fc:00:00:00:01" /tmp/wol.txt

nmap -e veth-host --script broadcast-ping | tee /tmp/bping.txt
grep -q "IP: 192.168.50.1" /tmp/bping.txt
