#!/bin/bash
set -e
sudo rm -f /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get install -y nmap
pip install -r requirements.txt
npm install -g --unsafe-perm node-red
