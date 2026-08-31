#!/bin/bash
set -e
cd "$(dirname "$0")/.."
command -v nmap
bash scripts/start.sh
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/502; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/1880; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/4840; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/1883; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/80; do sleep 1; done' 2>/dev/null
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/102; do sleep 1; done' 2>/dev/null
nmap -p 502 --script modbus-discover 127.0.0.1 | tee /tmp/modbus.txt
grep -q "502/tcp open  modbus" /tmp/modbus.txt
grep -q "Device identification: Aichi Company AIC-PLC-01" /tmp/modbus.txt
nmap -p 4840 --script ./opcua.nse 127.0.0.1 | tee /tmp/opcua.txt
grep -q "4840/tcp open  opcua" /tmp/opcua.txt
grep -q "opc.tcp://.*None (None), authentication:" /tmp/opcua.txt
grep -q "Server time: 2028-11-15 00:00:00Z" /tmp/opcua.txt
grep -q "Server time:" /tmp/opcua.txt
grep -q "Clock skew:" /tmp/opcua.txt
nmap -p 80 --script http-title,http-headers 127.0.0.1 | tee /tmp/http.txt
grep -q "http-title: Aichi Line1 HMI" /tmp/http.txt
grep -q "Server: AichiHTTP/1.0" /tmp/http.txt
grep -q "X-Powered-By: Aichi-HMI/2.1.4" /tmp/http.txt
nmap -p 80 --script http-date,clock-skew 127.0.0.1 | tee /tmp/httpdate.txt
grep -q "http-date: Wed, 15 Nov 2028 00:00:00 GMT" /tmp/httpdate.txt
grep -q "clock-skew:" /tmp/httpdate.txt
nmap -vv -p 4840 --script ./opcua.nse,clock-skew 127.0.0.1 | tee /tmp/opcua-skew.txt
grep -q "clock-skew:" /tmp/opcua-skew.txt
nmap -p 102 --script s7-info 127.0.0.1 | tee /tmp/s7.txt
grep -q "Module: AIC-CPU-3150" /tmp/s7.txt
grep -q "Basic Hardware: AIC-CPU-3150" /tmp/s7.txt
grep -q "Version: 2.6.9" /tmp/s7.txt
grep -q "System Name: Aichi Line1 Controller" /tmp/s7.txt
grep -q "Module Type: AIC CPU 3150" /tmp/s7.txt
grep -q "Serial Number: AIC-0001-0042" /tmp/s7.txt
grep -q "Copyright: Original Aichi Company Equipment" /tmp/s7.txt
