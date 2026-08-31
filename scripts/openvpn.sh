#!/bin/bash
set -e
cd "$(dirname "$0")/.."

mkdir -p work/vpn
if [ ! -f work/vpn/server.key ]; then
  openssl req -x509 -newkey rsa:2048 -keyout work/vpn/ca.key -out work/vpn/ca.crt \
    -days 3650 -nodes -subj "/CN=TestCA" 2>/dev/null
  openssl req -newkey rsa:2048 -keyout work/vpn/server.key -out work/vpn/server.csr \
    -nodes -subj "/CN=server" 2>/dev/null
  openssl x509 -req -in work/vpn/server.csr -CA work/vpn/ca.crt -CAkey work/vpn/ca.key \
    -CAcreateserial -out work/vpn/server.crt -days 3650 2>/dev/null
fi

cat > work/openvpn.conf << 'CONF'
dev tun
proto udp
port 1194
tls-server
ca work/vpn/ca.crt
cert work/vpn/server.crt
key work/vpn/server.key
dh none
mode server
server 10.8.0.0 255.255.255.0
verb 3
CONF

pgrep -a -x openvpn | grep -q "openvpn.conf" || setsid nohup \
  openvpn --config work/openvpn.conf < /dev/null > /tmp/openvpn.log 2>&1 &
sleep 5
