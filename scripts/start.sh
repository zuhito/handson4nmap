#!/bin/bash
cd "$(dirname "$0")/.."
pgrep -f modbus_server.py > /dev/null || setsid nohup python3 mock_servers/modbus_server.py < /dev/null > /tmp/modbus.log 2>&1 &
pgrep -f opcua_server.py > /dev/null || setsid nohup python3 mock_servers/opcua_server.py < /dev/null > /tmp/opcua.log 2>&1 &
pgrep -f profinet-server.py > /dev/null || setsid nohup python3 mock_servers/profinet-server.py < /dev/null > /tmp/profinet.log 2>&1 &
pgrep -f openvpn-udp.conf > /dev/null || setsid nohup openvpn --config scripts/openvpn-udp.conf < /dev/null > /tmp/openvpn-udp.log 2>&1 &
pgrep -f openvpn-tcp.conf > /dev/null || setsid nohup openvpn --config scripts/openvpn-tcp.conf < /dev/null > /tmp/openvpn-tcp.log 2>&1 &
pgrep -f "scripts/mosquitto.conf" > /dev/null || setsid nohup mosquitto -c scripts/mosquitto.conf < /dev/null > /tmp/mosquitto.log 2>&1 &
pgrep -f "scripts/mosquitto-auth.conf" > /dev/null || setsid nohup mosquitto -c scripts/mosquitto-auth.conf < /dev/null > /tmp/mosquitto-auth.log 2>&1 &
pgrep -f http_clockskew_server.py > /dev/null || setsid nohup python3 mock_servers/http_clockskew_server.py < /dev/null > /tmp/httpskew.log 2>&1 &
pgrep -f mqtt_publisher.py > /dev/null || setsid nohup python3 mock_servers/mqtt_publisher.py < /dev/null > /tmp/mqttpub.log 2>&1 &
pgrep -f s7_server.py > /dev/null || setsid nohup python3 mock_servers/s7_server.py < /dev/null > /tmp/s7.log 2>&1 &
pgrep -f codesys_server.py > /dev/null || setsid nohup python3 mock_servers/codesys_server.py < /dev/null > /tmp/codesys.log 2>&1 &
pgrep -x node-red > /dev/null || setsid nohup node-red < /dev/null > /tmp/nodered.log 2>&1 &
bash scripts/dhcp-start.sh

exit 0
