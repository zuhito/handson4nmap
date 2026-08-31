#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 1 bash -c ': > /dev/tcp/127.0.0.1/5900' 2>/dev/null || setsid nohup python3 mock_servers/vnc_server.py < /dev/null > /tmp/vnc.log 2>&1 &
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/5900; do sleep 1; done' 2>/dev/null
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/5901; do sleep 1; done' 2>/dev/null

# An unauthenticated server is reported with a warning.
nmap -p 5900 --script vnc-info 127.0.0.1 | tee /tmp/vnc-open.txt
grep -q "5900/tcp open  vnc" /tmp/vnc-open.txt
grep -q "Protocol version: 3.8" /tmp/vnc-open.txt
grep -q "None (1)" /tmp/vnc-open.txt
grep -q "Server does not require authentication" /tmp/vnc-open.txt

# With VNC authentication a different security type is offered.
nmap -p 5901 --script vnc-info 127.0.0.1 | tee /tmp/vnc-auth.txt
grep -q "VNC Authentication (2)" /tmp/vnc-auth.txt
