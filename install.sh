#!/bin/bash
set -e
rm -f /etc/apt/sources.list.d/yarn.list
apt-get update
apt-get install -y nmap openvpn
pip install -r requirements.txt
npm install -g --unsafe-perm node-red
bash profinet-nse.sh

mkdir -p vpn
openssl req -x509 -newkey rsa:2048 -keyout vpn/ca.key -out vpn/ca.crt -days 3650 -nodes -subj "/CN=TestCA"
openssl req -newkey rsa:2048 -keyout vpn/server.key -out vpn/server.csr -nodes -subj "/CN=server"
openssl x509 -req -in vpn/server.csr -CA vpn/ca.crt -CAkey vpn/ca.key -CAcreateserial -out vpn/server.crt -days 3650
