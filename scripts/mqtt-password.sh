#!/bin/bash
set -e

# mosquitto refuses to start if the password file is missing.
touch /tmp/mosquitto.pw
chmod 600 /tmp/mosquitto.pw
mosquitto_passwd -b /tmp/mosquitto.pw username password
