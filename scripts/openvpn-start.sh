#!/bin/bash
set -e
cd "$(dirname "$0")/.."

pgrep -a -x openvpn | grep -q "openvpn.conf" || setsid nohup openvpn --config scripts/openvpn.conf < /dev/null > /tmp/openvpn.log 2>&1 &
# UDP cannot be probed with a connect, so wait for the server to report that
# it finished its initialisation.
timeout 60 bash -c 'until grep -q "Initialization Sequence Completed" /tmp/openvpn.log; do sleep 1; done'
