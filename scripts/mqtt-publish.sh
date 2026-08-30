#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# Retained messages stay in the broker, so publishing once is enough for
# mqtt-subscribe to see them on every scan.
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/1883; do sleep 1; done' 2>/dev/null

# The PLC itself reports its own run state, while the measurements belong to
# the equipment the PLC controls.
mosquitto_pub -h 127.0.0.1 -r -t aichi/line1/plc01/status -m running
mosquitto_pub -h 127.0.0.1 -r -t aichi/line1/tank01/pressure -m 101.3
mosquitto_pub -h 127.0.0.1 -r -t aichi/line1/motor01/current -m 12.7

# A second namespace so that the effect of a topic filter is visible.
mosquitto_pub -h 127.0.0.1 -r -t site/building1/room101/temperature -m 25.4
mosquitto_pub -h 127.0.0.1 -r -t site/building1/meter01/energy -m 1042
