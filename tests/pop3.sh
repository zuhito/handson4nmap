#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 1 bash -c ': > /dev/tcp/127.0.0.1/110' 2>/dev/null || setsid nohup python3 mock_servers/pop3_server.py < /dev/null > /tmp/pop3.log 2>&1 &
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/110; do sleep 1; done' 2>/dev/null

nmap -p 110 --script pop3.nse 127.0.0.1 | tee /tmp/pop3.txt
grep -q "110/tcp open  pop3" /tmp/pop3.txt
grep -q "Greeting: Aichi Mail POP3 server ready" /tmp/pop3.txt
grep -q "Authentication: PLAIN, LOGIN" /tmp/pop3.txt
grep -q "APOP: supported" /tmp/pop3.txt
grep -q "STLS: supported" /tmp/pop3.txt
grep -q "Implementation: Aichi-Mail-POP3 2.1.4" /tmp/pop3.txt
