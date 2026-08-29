#!/bin/bash
cd "$(dirname "$0")"

if ! pgrep -f "modbus_server.py" > /dev/null; then
  for py in /usr/local/python/current/bin/python3 "$(command -v python3)" /usr/bin/python3; do
    if [ -x "$py" ] && "$py" -c "import pymodbus" 2>/dev/null; then
      sudo setsid nohup "$py" modbus_server.py < /dev/null > /tmp/modbus.log 2>&1 &
      break
    fi
  done
fi

if ! pgrep -x "node-red" > /dev/null; then
  setsid nohup node-red < /dev/null > /tmp/nodered.log 2>&1 &
fi

exit 0
