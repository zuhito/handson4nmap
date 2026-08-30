#!/bin/bash
cd "$(dirname "$0")/.."
pgrep -f modbus_server.py > /dev/null || setsid nohup python3 mock_servers/modbus_server.py < /dev/null > /tmp/modbus.log 2>&1 &
pgrep -f opcua_server.py > /dev/null || setsid nohup python3 mock_servers/opcua_server.py < /dev/null > /tmp/opcua.log 2>&1 &
pgrep -f profinet-server.py > /dev/null || setsid nohup python3 mock_servers/profinet-server.py < /dev/null > /tmp/profinet.log 2>&1 &
pgrep -f openvpn-udp.conf > /dev/null || setsid nohup openvpn --config scripts/openvpn-udp.conf < /dev/null > /tmp/openvpn-udp.log 2>&1 &
pgrep -f openvpn-tcp.conf > /dev/null || setsid nohup openvpn --config scripts/openvpn-tcp.conf < /dev/null > /tmp/openvpn-tcp.log 2>&1 &
pgrep -f mosquitto.conf > /dev/null || setsid nohup mosquitto -c scripts/mosquitto.conf < /dev/null > /tmp/mosquitto.log 2>&1 &
pgrep -x node-red > /dev/null || setsid nohup node-red < /dev/null > /tmp/nodered.log 2>&1 &
exit 0
