#!/bin/bash
set -e
rm -f /etc/apt/sources.list.d/yarn.list
apt-get update
apt-get install -y nmap
pip install -r requirements.txt
