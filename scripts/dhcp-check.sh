#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/dhcp-start.sh
sleep 3

nmap -sU -p 67 --script dhcp-discover 192.168.50.1 | tee /tmp/dhcp.txt
grep -q "67/udp open  dhcps" /tmp/dhcp.txt
grep -q "Server Identifier: 192.168.50.1" /tmp/dhcp.txt
grep -q "Domain Name: aichi.example" /tmp/dhcp.txt

nmap --script broadcast-dhcp-discover -e veth-host | tee /tmp/dhcp-bcast.txt
grep -q "DHCP Message Type: DHCPOFFER" /tmp/dhcp-bcast.txt
grep -q "IP Offered: 192.168.50." /tmp/dhcp-bcast.txt
grep -q "Router: 192.168.50.1" /tmp/dhcp-bcast.txt
