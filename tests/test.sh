#!/bin/bash
set -e
cd "$(dirname "$0")/.."
bash tests/core.sh
bash scripts/profinet-check.sh
bash tests/mqtt-subscribe.sh
bash tests/openvpn.sh
bash tests/codesys.sh
bash tests/snmp.sh
bash tests/ntp.sh
bash tests/grafana.sh
bash tests/influxdb.sh
bash tests/vnc.sh
bash tests/imap.sh
bash tests/pop3.sh
bash tests/smtp.sh
bash tests/mysql.sh
bash tests/ssh.sh
bash tests/report.sh
bash tests/readme.sh
