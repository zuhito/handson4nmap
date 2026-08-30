#!/bin/bash
set -e
cd "$(dirname "$0")/.."
command -v nmap
bash scripts/start.sh
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/502; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/1880; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/4840; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/1883; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/1884; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/8000; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/102; do sleep 1; done' 2>/dev/null
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
nmap -p 1884 --script ./mqtt.nse 127.0.0.1 | tee /tmp/mqtt-auth.txt
grep -q "1884/tcp open  mqtt" /tmp/mqtt-auth.txt
grep -q "Protocol: MQTT 3.1.1" /tmp/mqtt-auth.txt
grep -q "Connection: Not authorized (0x05)" /tmp/mqtt-auth.txt
grep -q "Anonymous access: denied" /tmp/mqtt-auth.txt
nmap -p 8000 --script http-date,clock-skew 127.0.0.1 | tee /tmp/httpdate.txt
grep -q "+4m51s from local time" /tmp/httpdate.txt
grep -q "clock-skew: 4m5" /tmp/httpdate.txt
nmap -vv -p 4840 --script ./opcua.nse,clock-skew 127.0.0.1 | tee /tmp/opcua-skew.txt
grep -q "clock-skew:" /tmp/opcua-skew.txt
nmap -p 102 --script s7-info 127.0.0.1 | tee /tmp/s7.txt
grep -q "Module: 6ES7 315-2AG10-0AB0" /tmp/s7.txt
grep -q "Basic Hardware: 6ES7 315-2AG10-0AB0" /tmp/s7.txt
grep -q "Version: 2.6.9" /tmp/s7.txt
grep -q "System Name: SIMATIC 300(Aichi)" /tmp/s7.txt
grep -q "Module Type: CPU 315-2 DP" /tmp/s7.txt
grep -q "Serial Number: S C-AIC421302009" /tmp/s7.txt
grep -q "Copyright: Original Siemens Equipment" /tmp/s7.txt
