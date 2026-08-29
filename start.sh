#!/bin/bash
cd "$(dirname "$0")"
setsid nohup python3 modbus_server.py < /dev/null > /tmp/modbus.log 2>&1 &
setsid nohup node-red < /dev/null > /tmp/nodered.log 2>&1 &
