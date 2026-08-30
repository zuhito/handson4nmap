#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/vnc-start.sh

# Without authentication the handshake reaches ServerInit.
nmap -p 5900 --script vnc.nse 127.0.0.1 | tee /tmp/vnc-open.txt
grep -q "5900/tcp open  vnc" /tmp/vnc-open.txt
grep -q "Protocol version: 3.8" /tmp/vnc-open.txt
grep -q "Security types: None (1)" /tmp/vnc-open.txt
grep -q "Authentication: not required" /tmp/vnc-open.txt
grep -q "Desktop name: Aichi Line1 HMI" /tmp/vnc-open.txt
grep -q "Framebuffer: 1024x768" /tmp/vnc-open.txt

# With VNC authentication the desktop details stay hidden.
nmap -p 5901 --script vnc.nse 127.0.0.1 | tee /tmp/vnc-auth.txt
grep -q "Security types: VNC Authentication (2)" /tmp/vnc-auth.txt
grep -q "Authentication: required" /tmp/vnc-auth.txt
! grep -q "Desktop name:" /tmp/vnc-auth.txt
