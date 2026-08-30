#!/bin/bash
set -e
cd "$(dirname "$0")/.."
bash tests/core.sh
bash scripts/dhcp-check.sh
bash scripts/pnet-check.sh
bash scripts/profinet-check.sh
bash tests/mqtt-subscribe.sh
bash tests/codesys.sh
bash tests/snmp.sh
bash tests/report.sh
