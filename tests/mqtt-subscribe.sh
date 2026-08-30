#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# Without a topic filter every retained topic is listed.
nmap -p 1883 --script mqtt-subscribe 127.0.0.1 | tee /tmp/mqtt-subscribe.txt
grep -q "aichi/plc01/temperature: 25.4" /tmp/mqtt-subscribe.txt
grep -q "aichi/plc01/pressure: 101.3" /tmp/mqtt-subscribe.txt
grep -q "aichi/plc01/status: running" /tmp/mqtt-subscribe.txt
grep -q "site/line1/counter: 1042" /tmp/mqtt-subscribe.txt
grep -q "site/line1/state: idle" /tmp/mqtt-subscribe.txt
# sys_interval 0 must keep the broker statistics out of the output.
! grep -q "[$]SYS/" /tmp/mqtt-subscribe.txt

# The topic filter must drop the second namespace.
nmap -p 1883 --script mqtt-subscribe --script-args 'mqtt-subscribe.topic=aichi/#' 127.0.0.1 | tee /tmp/mqtt-filtered.txt
grep -q "aichi/plc01/temperature: 25.4" /tmp/mqtt-filtered.txt
grep -q "aichi/plc01/status: running" /tmp/mqtt-filtered.txt
! grep -q "site/line1/" /tmp/mqtt-filtered.txt
