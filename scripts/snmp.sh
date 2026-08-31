#!/bin/bash
set -e
cd "$(dirname "$0")/.."

mkdir -p work
cat > work/snmpd.conf << 'CONF'
agentaddress udp:0.0.0.0:161
rocommunity public
sysDescr Aichi Company AIC-PLC-01 controller
sysContact handson@example.com
sysLocation Aichi Test Line
CONF

pgrep -x snmpd > /dev/null || setsid nohup \
  snmpd -f -C -c "$PWD/work/snmpd.conf" -Lo < /dev/null > /tmp/snmpd.log 2>&1 &
