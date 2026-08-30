#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# A DHCP request sent to an address of the scanning host itself arrives over the
# loopback interface and dnsmasq rejects it as out of range. A veth pair with the
# server in its own network namespace gives the request a real link to arrive on.
ip netns list | grep -qw dhcptest || ip netns add dhcptest
ip link show veth-host > /dev/null 2>&1 || ip link add veth-host type veth peer name veth-ns
ip link show veth-ns > /dev/null 2>&1 && ip link set veth-ns netns dhcptest || true

ip addr add 192.168.50.2/24 dev veth-host 2>/dev/null || true
ip link set veth-host up
ip netns exec dhcptest ip addr add 192.168.50.1/24 dev veth-ns 2>/dev/null || true
ip netns exec dhcptest ip link set veth-ns up
ip netns exec dhcptest ip link set lo up

pgrep -x dnsmasq > /dev/null || setsid nohup ip netns exec dhcptest \
  dnsmasq -C "$PWD/scripts/dnsmasq.conf" --no-daemon < /dev/null > /tmp/dnsmasq.log 2>&1 &
