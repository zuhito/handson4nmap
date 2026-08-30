#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# A DHCP request sent to an address of the scanning host itself arrives over the
# loopback interface and dnsmasq rejects it as out of range. Broadcast probes are
# sent as raw ethernet frames and never reach a local UDP socket either. Putting
# the server in its own network namespace gives both probes a real link.
pkill -x dnsmasq || true
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

setsid nohup ip netns exec dhcptest \
  dnsmasq -C "$PWD/scripts/dnsmasq.conf" --no-daemon < /dev/null > /tmp/dnsmasq.log 2>&1 &
