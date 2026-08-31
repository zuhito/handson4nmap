#!/bin/bash
set -e
cd "$(dirname "$0")/.."

nmap -p 1883 --script mqtt-subscribe 127.0.0.1 | tee /tmp/mqtt-subscribe.txt
grep -q "aichi/line1/status: running" /tmp/mqtt-subscribe.txt
grep -q "aichi/line1/pressure: 101.3" /tmp/mqtt-subscribe.txt
grep -q "aichi/line1/current: 12.7" /tmp/mqtt-subscribe.txt
grep -q "aichi/line2/status: stopped" /tmp/mqtt-subscribe.txt
grep -q "aichi/line2/pressure: 0.0" /tmp/mqtt-subscribe.txt
! grep -q "[$]SYS/" /tmp/mqtt-subscribe.txt

nmap -p 1883 --script mqtt-subscribe --script-args 'mqtt-subscribe.topic=aichi/line1/#' 127.0.0.1 | tee /tmp/mqtt-filtered.txt
grep -q "aichi/line1/pressure: 101.3" /tmp/mqtt-filtered.txt
grep -q "aichi/line1/status: running" /tmp/mqtt-filtered.txt
! grep -q "aichi/line2/" /tmp/mqtt-filtered.txt

! grep -q "nagoya/" /tmp/mqtt-subscribe.txt

nmap -p 1883 --script mqtt-subscribe --script-args "mqtt-subscribe.username=username,mqtt-subscribe.password=password" 127.0.0.1 | tee /tmp/mqtt-auth.txt
grep -q "nagoya/line1/status: running" /tmp/mqtt-auth.txt
grep -q "nagoya/line1/temperature: 180" /tmp/mqtt-auth.txt
grep -q "aichi/line1/status: running" /tmp/mqtt-auth.txt

