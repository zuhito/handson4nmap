#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# Retained messages stay in the broker, so publishing once is enough for
# mqtt-subscribe to see them on every scan.
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/1883; do sleep 1; done' 2>/dev/null

# The ACL only grants read access to anonymous clients, so publishing needs
# credentials even for the topics everyone may read.
# Two production lines of the same plant. line1 is running, line2 is stopped.
mosquitto_pub -h 127.0.0.1 -u username -P passwprod -r -t aichi/line1/status -m running
mosquitto_pub -h 127.0.0.1 -u username -P passwprod -r -t aichi/line1/pressure -m 101.3
mosquitto_pub -h 127.0.0.1 -u username -P passwprod -r -t aichi/line1/current -m 12.7
mosquitto_pub -h 127.0.0.1 -u username -P passwprod -r -t aichi/line2/status -m stopped
mosquitto_pub -h 127.0.0.1 -u username -P passwprod -r -t aichi/line2/pressure -m 0.0

# Only the maintenance user may read these, so they need credentials to publish.
mosquitto_pub -h 127.0.0.1 -u username -P passwprod -r -t nagoya/line1/status -m running
mosquitto_pub -h 127.0.0.1 -u username -P passwprod -r -t nagoya/line1/temperature -m 180
mosquitto_pub -h 127.0.0.1 -u username -P passwprod -r -t nagoya/line2/status -m maintenance
