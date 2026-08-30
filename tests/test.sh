#!/bin/bash
set -e
cd "$(dirname "$0")/.."
bash tests/core.sh
bash scripts/dhcp-check.sh
bash scripts/pnet-check.sh
bash scripts/profinet-check.sh
bash tests/mqtt-subscribe.sh
bash tests/openvpn.sh
bash tests/codesys.sh
bash tests/snmp.sh
bash tests/mysql.sh
bash tests/ntp.sh
bash tests/report.sh
