#!/bin/bash

set -e

ESC_SEQ="\x1b["
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

echo -e "${COL_CYAN}** Setting up APT info$COL_RESET"
if [[ ! -f /etc/apt/sources.list.d/starkandwayne.list ]]; then
  sudo apt-get update
  sudo apt-get install wget -y
  wget -q -O - https://raw.githubusercontent.com/starkandwayne/homebrew-cf/master/public.key | sudo apt-key add -
  echo "deb http://apt.starkandwayne.com stable main" | sudo tee /etc/apt/sources.list.d/starkandwayne.list
fi

echo -e "${COL_CYAN}** Installing packages$COL_RESET"
sudo apt-get update
sudo apt-get install postgresql-9.5 concourse vault spruce safe jq nmap

echo -e "${COL_CYAN}** Adding Vault user$COL_RESET"
if ! id vault >/dev/null 2>&1; then
  sudo useradd --system --shell /bin/nologin vault
fi

echo -e "${COL_CYAN}** Adding Concourse user$COL_RESET"
if ! id concourse > /dev/null 2>&1; then
  sudo useradd --system --shell /bin/nologin concourse
fi

echo -e "${COL_CYAN}** Creating Directories$COL_RESET"
sudo mkdir -p /opt/vault
sudo chown vault /opt/vault

sudo mkdir -p /opt/concourse
sudo chown concourse /opt/concourse


echo -e "${COL_CYAN}** Configuring Systemd$COL_RESET"
sudo mkdir -p /usr/lib/systemd/system
sudo cp vault.service /usr/lib/systemd/system/
sudo cp concourse-web.service /usr/lib/systemd/system/
sudo cp concourse-worker.service /usr/lib/systemd/system/
sudo cp papertrail.service /usr/lib/systemd/system/
sudo systemctl daemon-reload

echo -e "${COL_CYAN}** Enabling services at boot$COL_RESET"
sudo systemctl enable vault
sudo systemctl enable concourse-web
sudo systemctl enable concourse-worker
sudo systemctl enable papertrail
sudo systemctl enable postgresql

echo -e "${COL_CYAN}** Configuring postgres$COL_RESET"
sudo cp postgresql.conf /etc/postgresql/9.5/main/
sudo cp pg_hba.conf /etc/postgresql/9.5/main/

echo -e "${COL_CYAN}** Configuring concourse$COL_RESET"
sudo mkdir -p /etc/concourse
sudo cp concourse.conf /etc/concourse
if ! sudo test -f /etc/concourse/tsa_host_key; then
  sudo ssh-keygen -t rsa -f /etc/concourse/tsa_host_key -N ''
fi
if ! sudo test -f /etc/concourse/worker_key; then
  sudo ssh-keygen -t rsa -f /etc/concourse/worker_key -N ''
fi
if ! sudo test -f /etc/concourse/session_signing_key; then
  sudo ssh-keygen -t rsa -f /etc/concourse/session_signing_key -N ''
fi
sudo chown -R concourse:concourse /etc/concourse
sudo chmod -R 600 /etc/concourse
sudo chmod 700 /etc/concourse

echo -e "${COL_GREEN}** System configured. Don't forget to restart services appropriately$COL_RESET"
