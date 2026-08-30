#!/bin/bash
set -e
cd "$(dirname "$0")/.."
bash tests/core.sh
bash scripts/dhcp-check.sh
bash scripts/pnet-check.sh
bash scripts/profinet-check.sh mock_servers/profinet-server.py
bash scripts/profinet-check.sh mock_servers/profinet-server2.py
bash tests/report.sh
