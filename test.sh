#!/bin/bash
set -e
nohup python3 modbus_test.py > /tmp/modbus.log 2>&1 &
nohup python3 nodered_test.py > /tmp/nodered.log 2>&1 &
for port in 502 1880; do
  until timeout 1 bash -c ": >/dev/tcp/127.0.0.1/$port" 2>/dev/null; do sleep 1; done
done
nmap -p 502 --script modbus-discover 127.0.0.1
nmap -p 1880 --script ./node-red-diagnostics.nse 127.0.0.1
