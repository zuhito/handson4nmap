#!/bin/bash
set -e
cd "$(dirname "$0")/.."

pgrep -f dnsmasq-dns.conf > /dev/null || setsid nohup dnsmasq -C scripts/dnsmasq-dns.conf --no-daemon < /dev/null > /tmp/dnsmasq-dns.log 2>&1 &

# UDP has no connect based readiness check, so retry until the server answers.
for _ in $(seq 1 30); do
  nmap -sU -p 53 --script dns.nse 127.0.0.1 > /tmp/dns.txt
  grep -q "Version:" /tmp/dns.txt && break
  sleep 2
done
cat /tmp/dns.txt

grep -q "53/udp open" /tmp/dns.txt
grep -q "Version: dnsmasq-" /tmp/dns.txt
grep -q "Response code: NOERROR" /tmp/dns.txt
grep -q "Recursion:" /tmp/dns.txt
