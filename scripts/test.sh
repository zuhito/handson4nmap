#!/bin/bash
set -e
cd "$(dirname "$0")/.."
command -v nmap
bash scripts/start.sh
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/502; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/1880; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/4840; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/1883; do sleep 1; done' 2>/dev/null
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
grep -q "Clock skew:" /tmp/opcua.txt
nmap -p 1883 --script ./mqtt.nse 127.0.0.1 | tee /tmp/mqtt.txt
grep -q "1883/tcp open  mqtt" /tmp/mqtt.txt
grep -q "Protocol: MQTT 5.0" /tmp/mqtt.txt
grep -q "Anonymous access: allowed" /tmp/mqtt.txt
grep -q "Session present:" /tmp/mqtt.txt
bash scripts/profinet-check.sh mock_servers/profinet-server.py
bash scripts/profinet-check.sh mock_servers/profinet-server2.py

