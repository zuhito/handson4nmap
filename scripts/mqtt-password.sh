#!/bin/bash
set -e

touch /tmp/mosquitto.pw
chmod 600 /tmp/mosquitto.pw
mosquitto_passwd -b /tmp/mosquitto.pw username password
