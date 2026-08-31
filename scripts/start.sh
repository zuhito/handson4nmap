#!/bin/bash
cd "$(dirname "$0")/.."
pgrep -f modbus_server.py > /dev/null || setsid nohup python3 scripts/modbus_server.py < /dev/null > /tmp/modbus.log 2>&1 &
pgrep -f opcua_server_clockskew.py > /dev/null || setsid nohup python3 scripts/opcua_server_clockskew.py < /dev/null > /tmp/opcua.log 2>&1 &
pgrep -f profinet-server.py > /dev/null || setsid nohup python3 scripts/profinet-server.py < /dev/null > /tmp/profinet.log 2>&1 &
pgrep -f http_server_clockskew.py > /dev/null || setsid nohup python3 scripts/http_server_clockskew.py < /dev/null > /tmp/httpskew.log 2>&1 &
pgrep -f ntp_server_clockskew.py > /dev/null || setsid nohup python3 scripts/ntp_server_clockskew.py < /dev/null > /tmp/ntp.log 2>&1 &
pgrep -f imap_server.py > /dev/null || setsid nohup python3 scripts/imap_server.py < /dev/null > /tmp/imap.log 2>&1 &
pgrep -f pop3_server.py > /dev/null || setsid nohup python3 scripts/pop3_server.py < /dev/null > /tmp/pop3.log 2>&1 &
pgrep -f smtp_server.py > /dev/null || setsid nohup python3 scripts/smtp_server.py < /dev/null > /tmp/smtp.log 2>&1 &
pgrep -f s7_server.py > /dev/null || setsid nohup python3 scripts/s7_server.py < /dev/null > /tmp/s7.log 2>&1 &
pgrep -f vnc_server.py > /dev/null || setsid nohup python3 scripts/vnc_server.py < /dev/null > /tmp/vnc.log 2>&1 &
pgrep -x node-red > /dev/null || setsid nohup node-red < /dev/null > /tmp/nodered.log 2>&1 &

bash scripts/mariadb.sh
bash scripts/mqtt.sh
bash scripts/dns.sh
bash scripts/snmp.sh
bash scripts/openvpn.sh
bash scripts/ssh.sh
bash scripts/dhcp.sh

exit 0
