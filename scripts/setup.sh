#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/install.sh
bash scripts/nmap-build.sh
bash scripts/codesys-nse.sh
bash scripts/busybox-build.sh
bash scripts/grafana-install.sh
bash scripts/opencart-install.sh
