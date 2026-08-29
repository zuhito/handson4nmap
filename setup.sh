#!/bin/bash
set -e
apt-get update
apt-get install -y nmap
pip install -r requirements.txt
