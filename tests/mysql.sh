#!/bin/bash
set -e
cd "$(dirname "$0")/.."

pgrep -x mariadbd > /dev/null || setsid nohup mariadbd-safe --user=mysql < /dev/null > /tmp/mariadb.log 2>&1 &
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/3306; do sleep 1; done' 2>/dev/null

nmap -p 3306 --script mysql.nse 127.0.0.1 | tee /tmp/mysql.txt
grep -q "3306/tcp open" /tmp/mysql.txt
grep -q "Version: .*MariaDB" /tmp/mysql.txt
grep -q "Protocol: 10" /tmp/mysql.txt
grep -q "Authentication plugin: mysql_native_password" /tmp/mysql.txt
grep -q "TLS: " /tmp/mysql.txt
grep -q "Capabilities: .*PROTOCOL_41" /tmp/mysql.txt
