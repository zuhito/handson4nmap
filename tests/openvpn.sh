#!/bin/bash
set -e
cd "$(dirname "$0")/.."

nmap -sU -p 1194 --script openvpn.nse 127.0.0.1 | tee /tmp/openvpn.txt
grep -q "1194/udp open  openvpn" /tmp/openvpn.txt
grep -q "P_CONTROL_HARD_RESET_SERVER_V2" /tmp/openvpn.txt
grep -q "Client session acknowledged: yes" /tmp/openvpn.txt
