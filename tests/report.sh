#!/bin/bash
set -e
cd "$(dirname "$0")/.."

nmap -p 80,502,1880,1883,4840 \
  --script modbus-discover,./node-red.nse,./mqtt.nse,./opcua.nse,http-date \
  -oX /tmp/scan.xml 127.0.0.1
xsl="$(dirname "$(command -v nmap)")/../share/nmap/nmap.xsl"
xsltproc -o /tmp/scan.html "$xsl" /tmp/scan.xml

grep -q "Aichi Company AIC-PLC-01" /tmp/scan.html
grep -q "Node-RED:" /tmp/scan.html
grep -q "MQTT 5.0" /tmp/scan.html
grep -q "Endpoint URL" /tmp/scan.html
grep -q "Wed, 15 Nov 2028 00:00:00 GMT" /tmp/scan.html
