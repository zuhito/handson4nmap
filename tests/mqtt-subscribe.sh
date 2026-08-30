#!/bin/bash
set -e
cd "$(dirname "$0")/.."

nmap -p 1883 --script mqtt-subscribe 127.0.0.1 | tee /tmp/mqtt-subscribe.txt
grep -q "aichi/plc01/temperature: 25.4" /tmp/mqtt-subscribe.txt
grep -q "aichi/plc01/pressure: 101.3" /tmp/mqtt-subscribe.txt
grep -q "aichi/plc01/status: running" /tmp/mqtt-subscribe.txt
