#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# Retained messages stay in the broker, so publishing once is enough for
# mqtt-subscribe to see them on every scan.
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/1883; do sleep 1; done' 2>/dev/null
mosquitto_pub -h 127.0.0.1 -r -t aichi/plc01/temperature -m 25.4
mosquitto_pub -h 127.0.0.1 -r -t aichi/plc01/pressure -m 101.3
mosquitto_pub -h 127.0.0.1 -r -t aichi/plc01/status -m running
