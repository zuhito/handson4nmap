#!/bin/bash
set -e
cd "$(dirname "$0")/.."

mkdir -p work
cat > work/mosquitto.conf << 'CONF'
listener 1883
allow_anonymous true
persistence false
user root
password_file /tmp/mosquitto.pw
acl_file work/mosquitto.acl
sys_interval 0
CONF

cat > work/mosquitto.acl << 'CONF'
topic read aichi/#
topic read $SYS/#

user username
topic readwrite aichi/#
topic readwrite nagoya/#
CONF

touch /tmp/mosquitto.pw
chmod 600 /tmp/mosquitto.pw
mosquitto_passwd -b /tmp/mosquitto.pw username password

pgrep -x mosquitto > /dev/null || setsid nohup \
  mosquitto -c work/mosquitto.conf < /dev/null > /tmp/mosquitto.log 2>&1 &

timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/1883; do sleep 1; done' 2>/dev/null

mosquitto_pub -h 127.0.0.1 -u username -P password -r -t aichi/line1/status -m running
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t aichi/line1/pressure -m 101.3
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t aichi/line1/current -m 12.7
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t aichi/line2/status -m stopped
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t aichi/line2/pressure -m 0.0
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t nagoya/line1/status -m running
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t nagoya/line1/temperature -m 180
mosquitto_pub -h 127.0.0.1 -u username -P password -r -t nagoya/line2/status -m maintenance
