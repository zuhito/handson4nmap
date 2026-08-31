#!/bin/bash
set -e
cd "$(dirname "$0")/.."

for _ in $(seq 1 30); do
  nmap -sU -p 161 --script snmp-info,snmp-brute 127.0.0.1 > /tmp/snmp.txt
  grep -q "enterprise:" /tmp/snmp.txt && break
  sleep 2
done
cat /tmp/snmp.txt

grep -q "161/udp open  snmp" /tmp/snmp.txt
grep -q "enterprise: net-snmp" /tmp/snmp.txt
grep -q "snmpEngineBoots:" /tmp/snmp.txt
grep -q "public - Valid credentials" /tmp/snmp.txt
