#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# The container image has no Grafana package and packages.grafana.com is not
# reachable from CI, so the release is taken from GitHub.
mkdir -p external
url=$(curl -sfL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
  "https://api.github.com/repos/grafana/grafana/releases/latest" \
  | python3 -c "
import json, sys
for asset in json.load(sys.stdin)['assets']:
    if asset['name'].startswith('grafana_') and asset['name'].endswith('linux_amd64.deb'):
        print(asset['browser_download_url'])
        break
")
curl -sfL -o work/grafana.deb "$url"
dpkg -i work/grafana.deb
mkdir -p /tmp/grafana/data /tmp/grafana/logs /tmp/grafana/plugins
