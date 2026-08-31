#!/bin/bash
set -e
cd "$(dirname "$0")/.."

[ -f vpn/server.key ] || bash scripts/openvpn-keys.sh > /tmp/openvpn-keys.log 2>&1
pgrep -a -x openvpn | grep -q "openvpn.conf" || setsid nohup openvpn --config scripts/openvpn.conf < /dev/null > /tmp/openvpn.log 2>&1 &
sleep 5

nmap -sU -p 1194 --script openvpn.nse 127.0.0.1 | tee /tmp/openvpn.txt
grep -q "1194/udp open  openvpn" /tmp/openvpn.txt
grep -q "P_CONTROL_HARD_RESET_SERVER_V2" /tmp/openvpn.txt
grep -q "Client session acknowledged: yes" /tmp/openvpn.txt
