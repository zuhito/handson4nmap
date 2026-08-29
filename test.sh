#!/bin/bash
set -e
command -v nmap
bash start.sh
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/502; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/1880; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/4840; do sleep 1; done' 2>/dev/null
nmap -p 502 --script modbus-discover 127.0.0.1 | tee /tmp/modbus.txt
grep -q "502/tcp open  modbus" /tmp/modbus.txt
grep -q "Device identification: Aichi Company AIC-PLC-01" /tmp/modbus.txt
nmap -p 1880 --script ./node-red.nse 127.0.0.1 | tee /tmp/nodered.txt
grep -q "1880/tcp open  node-red" /tmp/nodered.txt
grep -q "Node-RED:" /tmp/nodered.txt
nmap -p 4840 --script ./opcua.nse 127.0.0.1 | tee /tmp/opcua.txt
grep -q "4840/tcp open  opcua" /tmp/opcua.txt
grep -q "Endpoint URL: opc.tcp://" /tmp/opcua.txt
grep -q "Authentication:" /tmp/opcua.txt
grep -q "Server time:" /tmp/opcua.txt
