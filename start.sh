#!/bin/bash
cd "$(dirname "$0")"

if ! pgrep -f "python3 modbus_server.py" > /dev/null; then
  setsid nohup python3 modbus_server.py < /dev/null > /tmp/modbus.log 2>&1 &
fi

if ! pgrep -x "node-red" > /dev/null; then
  setsid nohup node-red < /dev/null > /tmp/nodered.log 2>&1 &
fi

exit 0
