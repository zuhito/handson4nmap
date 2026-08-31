#!/bin/bash
set -e
cd "$(dirname "$0")/.."

# The container image has no Grafana package and packages.grafana.com is not
# reachable from CI, so the release is taken from GitHub.
mkdir -p work
# The API is rate limited for unauthenticated callers, so the release list is
# consulted as well before giving up.
auth=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
  auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

pick_asset() {
  python3 -c "
import json, sys
try:
    document = json.load(sys.stdin)
except ValueError:
    sys.exit(0)
for release in (document if isinstance(document, list) else [document]):
    if not isinstance(release, dict):
        continue
    for asset in release.get('assets', []):
        name = asset['name']
        if name.startswith('grafana_') and name.endswith('linux_amd64.deb'):
            print(asset['browser_download_url'])
            sys.exit(0)
"
}

url=$(curl -sfL "${auth[@]}" "https://api.github.com/repos/grafana/grafana/releases/latest" | pick_asset)
if [ -z "$url" ]; then
  url=$(curl -sfL "${auth[@]}" "https://api.github.com/repos/grafana/grafana/releases?per_page=20" | pick_asset)
fi
if [ -z "$url" ]; then
  echo "could not determine the Grafana download URL"
  exit 1
fi

curl -sfL -o work/grafana.deb "$url"
dpkg -i work/grafana.deb
mkdir -p /tmp/grafana/data /tmp/grafana/logs /tmp/grafana/plugins
