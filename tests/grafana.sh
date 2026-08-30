#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/3000; do sleep 1; done' 2>/dev/null

nmap -p 3000 --script ./grafana.nse 127.0.0.1 | tee /tmp/grafana.txt
grep -q "3000/tcp open  grafana" /tmp/grafana.txt
grep -q "Version: " /tmp/grafana.txt
grep -q "Database: ok" /tmp/grafana.txt
grep -q "Anonymous access: disabled" /tmp/grafana.txt
