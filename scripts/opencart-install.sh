#!/bin/bash
set -e
cd "$(dirname "$0")/.."
root="$PWD"

# The version is pinned so the setup does not depend on the GitHub API, which
# is rate limited for unauthenticated callers.
OPENCART_VERSION="${OPENCART_VERSION:-4.1.0.4}"

mkdir -p work
curl -sfL -o work/opencart.zip \
  "https://github.com/opencart/opencart/releases/download/${OPENCART_VERSION}/opencart-${OPENCART_VERSION}.zip"
rm -rf work/opencart
unzip -q work/opencart.zip -d work/opencart

cd work/opencart/upload
cp config-dist.php config.php
cp admin/config-dist.php admin/config.php

# install.sh runs before start.sh, so the database has to be brought up here.
bash "$root/scripts/mariadb-start.sh"

mysql -e "CREATE DATABASE IF NOT EXISTS opencart CHARACTER SET utf8mb4;"
mysql -e "CREATE USER IF NOT EXISTS 'opencart'@'localhost' IDENTIFIED BY 'opencart-pass';"
mysql -e "GRANT ALL ON opencart.* TO 'opencart'@'localhost'; FLUSH PRIVILEGES;"

php install/cli_install.php install \
  --username admin --email admin@aichi.example --password aichi-secret \
  --http_server http://127.0.0.1:8081/ \
  --db_driver mysqli --db_hostname 127.0.0.1 --db_username opencart \
  --db_password opencart-pass --db_database opencart --db_port 3306 --db_prefix oc_
