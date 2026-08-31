#!/bin/bash
set -e
cd "$(dirname "$0")/.."
rm -f /etc/apt/sources.list.d/yarn.list
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nmap openssh-server mariadb-server influxdb openvpn mosquitto mosquitto-clients xsltproc dnsmasq iproute2 libssl-dev libpcap-dev snmpd php-cli php-mysql php-gd php-curl php-zip php-mbstring php-xml unzip
pip install -r scripts/requirements.txt
npm install -g --unsafe-perm node-red

mkdir -p work/vpn
openssl req -x509 -newkey rsa:2048 -keyout work/vpn/ca.key -out work/vpn/ca.crt -days 3650 -nodes -subj "/CN=TestCA"
openssl req -newkey rsa:2048 -keyout work/vpn/server.key -out work/vpn/server.csr -nodes -subj "/CN=server"
openssl x509 -req -in work/vpn/server.csr -CA work/vpn/ca.crt -CAkey work/vpn/ca.key -CAcreateserial -out work/vpn/server.crt -days 3650
