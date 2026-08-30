#!/bin/bash
set -e
cd "$(dirname "$0")/.."

pgrep -a -x openvpn | grep -q "openvpn-udp.conf" || setsid nohup openvpn --config scripts/openvpn-udp.conf < /dev/null > /tmp/openvpn-udp.log 2>&1 &
pgrep -a -x openvpn | grep -q "openvpn-tcp.conf" || setsid nohup openvpn --config scripts/openvpn-tcp.conf < /dev/null > /tmp/openvpn-tcp.log 2>&1 &
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/1194; do sleep 1; done' 2>/dev/null
