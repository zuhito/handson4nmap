#!/bin/bash
set -e
cd "$(dirname "$0")/.."

mkdir -p /tmp/vnc
printf 'vncpass\nvncpass\nn\n' | vncpasswd /tmp/vnc/passwd > /dev/null 2>&1

# :1 accepts unauthenticated clients so that ServerInit can be inspected,
# :2 requires the classic VNC challenge response.
pgrep -a -x Xvnc | grep -q ":1" || setsid nohup Xvnc :1 -rfbport 5900 \
  -SecurityTypes None -desktop "Aichi Line1 HMI" -geometry 1024x768 -depth 24 \
  < /dev/null > /tmp/vnc.log 2>&1 &
pgrep -a -x Xvnc | grep -q ":2" || setsid nohup Xvnc :2 -rfbport 5901 \
  -rfbauth /tmp/vnc/passwd -SecurityTypes VncAuth -desktop "Aichi Line2 HMI" \
  -geometry 800x600 -depth 16 < /dev/null > /tmp/vnc2.log 2>&1 &

timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/5900; do sleep 1; done' 2>/dev/null
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/5901; do sleep 1; done' 2>/dev/null
