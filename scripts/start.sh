#!/bin/bash
cd "$(dirname "$0")/.."
pgrep -f modbus_server.py > /dev/null || setsid nohup python3 mock_servers/modbus_server.py < /dev/null > /tmp/modbus.log 2>&1 &
pgrep -f opcua_server_clockskew.py > /dev/null || setsid nohup python3 mock_servers/opcua_server_clockskew.py < /dev/null > /tmp/opcua.log 2>&1 &
pgrep -f profinet-server.py > /dev/null || setsid nohup python3 mock_servers/profinet-server.py < /dev/null > /tmp/profinet.log 2>&1 &
# The certificates live outside the repository, so regenerate them if the
# container was created without running the installer.
[ -f work/vpn/server.key ] || bash scripts/openvpn-keys.sh > /tmp/openvpn-keys.log 2>&1
pgrep -a -x openvpn | grep -q "openvpn.conf" || setsid nohup openvpn --config scripts/openvpn.conf < /dev/null > /tmp/openvpn.log 2>&1 &
bash scripts/mqtt-password.sh
pgrep -a -x mosquitto | grep -q "scripts/mosquitto.conf" || setsid nohup mosquitto -c scripts/mosquitto.conf < /dev/null > /tmp/mosquitto.log 2>&1 &
pgrep -f http_server_clockskew.py > /dev/null || setsid nohup python3 mock_servers/http_server_clockskew.py < /dev/null > /tmp/httpskew.log 2>&1 &
setsid nohup bash scripts/mqtt-publish.sh < /dev/null > /tmp/mqttpub.log 2>&1 &
pgrep -f "php -S 0.0.0.0:8081" > /dev/null || setsid nohup php -S 0.0.0.0:8081 -t work/opencart/upload < /dev/null > /tmp/opencart.log 2>&1 &
pgrep -x grafana > /dev/null || setsid nohup grafana server --homepath /usr/share/grafana --config scripts/grafana.ini < /dev/null > /tmp/grafana.log 2>&1 &
pgrep -f s7_server.py > /dev/null || setsid nohup python3 mock_servers/s7_server.py < /dev/null > /tmp/s7.log 2>&1 &
pgrep -f codesys_server.py > /dev/null || setsid nohup python3 mock_servers/codesys_server.py < /dev/null > /tmp/codesys.log 2>&1 &
pgrep -x snmpd > /dev/null || setsid nohup snmpd -f -C -c scripts/snmpd.conf -Lo < /dev/null > /tmp/snmpd.log 2>&1 &
pgrep -f ntp_server_clockskew.py > /dev/null || setsid nohup python3 mock_servers/ntp_server_clockskew.py < /dev/null > /tmp/ntp.log 2>&1 &
bash scripts/mariadb-start.sh
pgrep -x influxd > /dev/null || setsid nohup influxd -config scripts/influxdb.conf < /dev/null > /tmp/influxdb.log 2>&1 &
pgrep -f vnc_server.py > /dev/null || setsid nohup python3 mock_servers/vnc_server.py < /dev/null > /tmp/vnc.log 2>&1 &
pgrep -f imap_server.py > /dev/null || setsid nohup python3 mock_servers/imap_server.py < /dev/null > /tmp/imap.log 2>&1 &
pgrep -f pop3_server.py > /dev/null || setsid nohup python3 mock_servers/pop3_server.py < /dev/null > /tmp/pop3.log 2>&1 &
pgrep -f dnsmasq-dns.conf > /dev/null || setsid nohup dnsmasq -C scripts/dnsmasq-dns.conf --no-daemon < /dev/null > /tmp/dnsmasq-dns.log 2>&1 &
pgrep -f smtp_server.py > /dev/null || setsid nohup python3 mock_servers/smtp_server.py < /dev/null > /tmp/smtp.log 2>&1 &
pgrep -x node-red > /dev/null || setsid nohup node-red < /dev/null > /tmp/nodered.log 2>&1 &
bash scripts/dhcp-start.sh

exit 0
setsid nohup bash scripts/influxdb-seed.sh < /dev/null > /tmp/influxdb-seed.log 2>&1 &
bash scripts/ssh-start.sh
setsid nohup bash scripts/grafana-datasource.sh < /dev/null > /tmp/grafana-datasource.log 2>&1 &
