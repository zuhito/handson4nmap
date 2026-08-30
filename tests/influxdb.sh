#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/influxdb-seed.sh

nmap -p 8086 --script influxdb.nse 127.0.0.1 | tee /tmp/influxdb.txt
grep -q "8086/tcp open  influxdb" /tmp/influxdb.txt
grep -q "Version: 1\." /tmp/influxdb.txt
grep -q "Build: OSS" /tmp/influxdb.txt
grep -q "Authentication: not required" /tmp/influxdb.txt
grep -q "Databases: .*plant" /tmp/influxdb.txt
