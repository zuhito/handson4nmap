#!/bin/bash
set -e
cd "$(dirname "$0")/.."

mkdir -p work/vpn
openssl req -x509 -newkey rsa:2048 -keyout work/vpn/ca.key -out work/vpn/ca.crt -days 3650 -nodes -subj "/CN=TestCA"
openssl req -newkey rsa:2048 -keyout work/vpn/server.key -out work/vpn/server.csr -nodes -subj "/CN=server"
openssl x509 -req -in work/vpn/server.csr -CA work/vpn/ca.crt -CAkey work/vpn/ca.key -CAcreateserial -out work/vpn/server.crt -days 3650
