#!/bin/bash
set -e
cd "$(dirname "$0")/.."

nmap -p 1194 --script openvpn.nse 127.0.0.1 | tee /tmp/openvpn-tcp.txt
grep -q "1194/tcp open  openvpn" /tmp/openvpn-tcp.txt
grep -q "P_CONTROL_HARD_RESET_SERVER_V2" /tmp/openvpn-tcp.txt
grep -q "Client session acknowledged: yes" /tmp/openvpn-tcp.txt

nmap -sU -p 1194 --script openvpn.nse 127.0.0.1 | tee /tmp/openvpn-udp.txt
grep -q "1194/udp open  openvpn" /tmp/openvpn-udp.txt
grep -q "Client session acknowledged: yes" /tmp/openvpn-udp.txt
