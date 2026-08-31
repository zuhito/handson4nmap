#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/openvpn.sh

sleep 5

nmap -sU -p 1194 127.0.0.1 | tee /tmp/openvpn.txt
grep -q "1194/udp open  openvpn" /tmp/openvpn.txt
