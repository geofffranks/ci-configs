#!/bin/bash

set -e

sudo apt-get update
sudo apt-get install wget -y
wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | apt-key add -
echo "deb http://apt.starkandwayne.com stable main" | tee /etc/apt/sources.list.d/starkandwayne.list

sudo apt-get update
sudo apt-get install postgresql-9.5 concourse vault spruce safe jq nmap

if ! id vault; then
  sudo useradd vault
fi
if ! id concourse; then
  sudo useradd concourse
fi

mkdir -p /opt/vault
sudo chown vault /opt/vault

mkdir -p /opt/concourse
sudo chown concourse /opt/concourse

sudo cp vault.service /usr/lib/systemd/system/
sudo cp concourse-web.service /usr/lib/systemd/system/
sudo cp concourse-worker.service /usr/lib/systemd/system/
sudo cp papertrail.service /usr/lib/systemd/system/
sudo systemctl daemon-reload

sudo systemctl enable vault
sudo systemctl enable concourse-web
sudo systemctl enable concourse-worker
sudo systemctl enable papertrail
sudo systemctl enable postgres

sudo cp postgresql.conf /etc/postgresql/9.5/main/
sudo cp pg_hba.conf /etc/postgresql/9.5/main/

sudo mkdir /etc/concourse
sudo cp concourse.conf /etc/concourse
sudo ssh-keygen -t rsa -f /etc/concourse/tsa_host_key -N ''
sudo ssh-keygen -t rsa -f /etc/concourse/worker_key -N ''
sudo ssh-keygen -t rsa -f /etc/concourse/session_signing_key -N ''
sudo chown -R concourse:concourse /etc/concourse
sudo chmod 600 /etc/concourse/*
sudo chmod 700 /etc/concourse

echo "System configured. Don't forget to restart services appropriately"
