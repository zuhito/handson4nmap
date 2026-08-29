#!/bin/bash
set -e
sudo apt-get update
sudo apt-get install -y nmap
pip install -r requirements.txt
