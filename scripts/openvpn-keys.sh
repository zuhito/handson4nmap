#!/bin/bash
set -e
cd "$(dirname "$0")/.."

mkdir -p vpn
openssl req -x509 -newkey rsa:2048 -keyout vpn/ca.key -out vpn/ca.crt -days 3650 -nodes -subj "/CN=TestCA"
openssl req -newkey rsa:2048 -keyout vpn/server.key -out vpn/server.csr -nodes -subj "/CN=server"
openssl x509 -req -in vpn/server.csr -CA vpn/ca.crt -CAkey vpn/ca.key -CAcreateserial -out vpn/server.crt -days 3650
