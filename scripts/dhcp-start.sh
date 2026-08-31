#!/bin/bash
set -e
cd "$(dirname "$0")/.."

for pid in $(pgrep -x dnsmasq); do
  tr '\0' ' ' < "/proc/$pid/cmdline" | grep -q "scripts/dnsmasq.conf" && kill "$pid" || true
done
ip netns del dhcptest 2>/dev/null || true
ip link del veth-host 2>/dev/null || true
sleep 1

ip netns add dhcptest
ip link add veth-host type veth peer name veth-ns
ip link set veth-ns netns dhcptest
ip addr add 192.168.50.2/24 dev veth-host
ip link set veth-host up
ip netns exec dhcptest ip addr add 192.168.50.1/24 dev veth-ns
ip netns exec dhcptest ip link set veth-ns up
ip netns exec dhcptest ip link set lo up

ip netns exec dhcptest sysctl -q -w net.ipv4.icmp_echo_ignore_broadcasts=0

setsid nohup ip netns exec dhcptest \
  dnsmasq -C "$PWD/scripts/dnsmasq.conf" --no-daemon < /dev/null > /tmp/dnsmasq.log 2>&1 &
