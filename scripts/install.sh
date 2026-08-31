#!/bin/bash
set -e
cd "$(dirname "$0")/.."
rm -f /etc/apt/sources.list.d/yarn.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nmap openssh-server mariadb-server openvpn mosquitto mosquitto-clients xsltproc dnsmasq iproute2 libssl-dev libpcap-dev snmpd unzip
pip install -r scripts/requirements.txt
npm install -g --unsafe-perm node-red


bash scripts/nmap.sh
bash scripts/busybox.sh
