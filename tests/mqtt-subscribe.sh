#!/bin/bash
set -e
cd "$(dirname "$0")/.."

nmap -p 1883 --script mqtt-subscribe --script-args 'mqtt-subscribe.topic=aichi/#' 127.0.0.1 | tee /tmp/mqtt-subscribe.txt
grep -q "aichi/plc01/temperature: 25.4" /tmp/mqtt-subscribe.txt
grep -q "aichi/plc01/pressure: 101.3" /tmp/mqtt-subscribe.txt
grep -q "aichi/plc01/status: running" /tmp/mqtt-subscribe.txt
# The topic filter must keep the broker statistics out of the output.
! grep -q "[$]SYS/" /tmp/mqtt-subscribe.txt
