#!/bin/bash
set -e
cd "$(dirname "$0")/.."

mkdir -p work
cat > work/dnsmasq-dns.conf << 'CONF'
port=53
listen-address=127.0.0.1
bind-interfaces
no-resolv
no-hosts
domain=aichi.example
add-cpe-id=Aichi-Mail
address=/plc01.aichi.example/192.168.50.11
address=/hmi01.aichi.example/192.168.50.12
address=/broker.aichi.example/192.168.50.13
ptr-record=11.50.168.192.in-addr.arpa,plc01.aichi.example
CONF

pgrep -f dnsmasq-dns.conf > /dev/null || setsid nohup \
  dnsmasq -C "$PWD/work/dnsmasq-dns.conf" --no-daemon < /dev/null > /tmp/dnsmasq-dns.log 2>&1 &
