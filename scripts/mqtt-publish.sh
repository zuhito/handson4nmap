#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/1883; do sleep 1; done' 2>/dev/null

mosquitto_pub -h 127.0.0.1 -u username -P password -r -t aichi/line1/status -m running
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t aichi/line1/pressure -m 101.3
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t aichi/line1/current -m 12.7
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t aichi/line2/status -m stopped
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t aichi/line2/pressure -m 0.0

mosquitto_pub -h 127.0.0.1 -u username -P password -r -t nagoya/line1/status -m running
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t nagoya/line1/temperature -m 180
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t nagoya/line2/status -m maintenance
