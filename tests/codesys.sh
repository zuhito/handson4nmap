#!/bin/bash
set -e
cd "$(dirname "$0")/.."

nmap -p 2455 --script codesys-v2-discover.nse 127.0.0.1 | tee /tmp/codesys.txt
grep -q "2455/tcp open  CoDeSyS" /tmp/codesys.txt
grep -q "OS Name: Linux 3.16.0" /tmp/codesys.txt
grep -q "Product Type: AIC-PLC-01" /tmp/codesys.txt
