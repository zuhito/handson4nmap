#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/mariadb-start.sh

nmap -p 3306 --script mysql.nse 127.0.0.1 | tee /tmp/mysql.txt
grep -q "3306/tcp open" /tmp/mysql.txt
grep -q "Version: .*MariaDB" /tmp/mysql.txt
grep -q "Protocol: 10" /tmp/mysql.txt
grep -q "Authentication plugin: mysql_native_password" /tmp/mysql.txt
grep -q "TLS: " /tmp/mysql.txt
grep -q "Capabilities: .*PROTOCOL_41" /tmp/mysql.txt
