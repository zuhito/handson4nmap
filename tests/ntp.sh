#!/bin/bash
set -e
cd "$(dirname "$0")/.."

for _ in $(seq 1 30); do
  nmap -sU -p 123 --script ntp-info 127.0.0.1 > /tmp/ntp.txt
  grep -q "receive time stamp" /tmp/ntp.txt && break
  sleep 2
done
cat /tmp/ntp.txt

grep -q "123/udp open  ntp" /tmp/ntp.txt
grep -q "receive time stamp" /tmp/ntp.txt
grep -q "receive time stamp: 2028-11-15T00:00:00" /tmp/ntp.txt
