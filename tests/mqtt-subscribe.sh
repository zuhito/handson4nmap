#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# Without a topic filter every retained topic is listed.
nmap -p 1883 --script mqtt-subscribe 127.0.0.1 | tee /tmp/mqtt-subscribe.txt
grep -q "aichi/line1/status: running" /tmp/mqtt-subscribe.txt
grep -q "aichi/line1/pressure: 101.3" /tmp/mqtt-subscribe.txt
grep -q "aichi/line1/current: 12.7" /tmp/mqtt-subscribe.txt
grep -q "aichi/line2/status: stopped" /tmp/mqtt-subscribe.txt
grep -q "aichi/line2/pressure: 0.0" /tmp/mqtt-subscribe.txt
# sys_interval 0 must keep the broker statistics out of the output.
! grep -q "[$]SYS/" /tmp/mqtt-subscribe.txt

# The topic filter must drop the second line.
nmap -p 1883 --script mqtt-subscribe --script-args 'mqtt-subscribe.topic=aichi/line1/#' 127.0.0.1 | tee /tmp/mqtt-filtered.txt
grep -q "aichi/line1/pressure: 101.3" /tmp/mqtt-filtered.txt
grep -q "aichi/line1/status: running" /tmp/mqtt-filtered.txt
! grep -q "aichi/line2/" /tmp/mqtt-filtered.txt
