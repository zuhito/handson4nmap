#!/bin/bash
set -e
nohup python3 modbus_server.py > /tmp/modbus.log 2>&1 &
nohup node-red > /tmp/nodered.log 2>&1 &
for port in 502 1880; do
  until timeout 1 bash -c ": >/dev/tcp/127.0.0.1/$port" 2>/dev/null; do sleep 1; done
done
nmap -p 502 --script modbus-discover 127.0.0.1
nmap -p 1880 --script ./node-red.nse 127.0.0.1
