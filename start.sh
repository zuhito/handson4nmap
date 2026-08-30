#!/bin/bash
cd "$(dirname "$0")"
pgrep -f modbus_server.py > /dev/null || setsid nohup python3 modbus_server.py < /dev/null > /tmp/modbus.log 2>&1 &
pgrep -f opcua_server.py > /dev/null || setsid nohup python3 opcua_server.py < /dev/null > /tmp/opcua.log 2>&1 &
pgrep -f profinet-server.py > /dev/null || setsid nohup python3 profinet-server.py < /dev/null > /tmp/profinet.log 2>&1 &
pgrep -x node-red > /dev/null || setsid nohup node-red < /dev/null > /tmp/nodered.log 2>&1 &
exit 0
