#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/mariadb-start.sh

nmap -p 3306 --script mysql-info 127.0.0.1 | tee /tmp/mysql.txt
grep -q "3306/tcp open" /tmp/mysql.txt
grep -q "Version: .*MariaDB" /tmp/mysql.txt
grep -q "Thread ID: " /tmp/mysql.txt
grep -q "Protocol: 10" /tmp/mysql.txt
grep -q "Auth Plugin Name: mysql_native_password" /tmp/mysql.txt
grep -q "Capabilities flags: " /tmp/mysql.txt
