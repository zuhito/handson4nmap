#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/3000; do sleep 1; done' 2>/dev/null

bash scripts/grafana-datasource.sh

nmap -p 3000 --script ./grafana.nse 127.0.0.1 | tee /tmp/grafana.txt
grep -q "3000/tcp open  grafana" /tmp/grafana.txt
grep -q "Version: " /tmp/grafana.txt
grep -q "Database: ok" /tmp/grafana.txt
grep -q "Anonymous access: disabled" /tmp/grafana.txt

# With credentials the script reports what the API exposes.
nmap -p 3000 --script grafana.nse \
  --script-args "grafana.username=admin,grafana.password=admin" 127.0.0.1 | tee /tmp/grafana-auth.txt
grep -q "Credentials: accepted" /tmp/grafana-auth.txt
grep -q "Organisation: Main Org." /tmp/grafana-auth.txt
grep -q "Users: admin (Admin" /tmp/grafana-auth.txt
grep -q "Data sources: plant-influx (influxdb" /tmp/grafana-auth.txt
grep -q "Statistics: " /tmp/grafana-auth.txt

# A wrong password must be reported rather than silently ignored.
nmap -p 3000 --script grafana.nse \
  --script-args "grafana.username=admin,grafana.password=wrong" 127.0.0.1 | tee /tmp/grafana-bad.txt
grep -q "Credentials: rejected" /tmp/grafana-bad.txt
