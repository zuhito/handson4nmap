#!/bin/bash
set -e

if ! command -v nmap > /dev/null; then
  rm -f /etc/apt/sources.list.d/yarn.list
  apt-get update
  apt-get install -y nmap
fi

pip install -r requirements.txt || pip install --break-system-packages -r requirements.txt

if ! command -v node-red > /dev/null; then
  npm install -g --unsafe-perm node-red
fi
