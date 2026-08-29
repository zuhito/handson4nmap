#!/bin/bash
set -e
sudo -E "$(which python3)" modbus_test.py >/dev/null 2>&1 &
until timeout 1 bash -c ": >/dev/tcp/127.0.0.1/502" 2>/dev/null; do sleep 1; done
nmap -p 502 --script modbus-discover 127.0.0.1
