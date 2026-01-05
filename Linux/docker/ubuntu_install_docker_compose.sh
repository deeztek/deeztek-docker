#!/bin/bash

# This script installs Docker Engine and the Docker Compose v2 plugin on Ubuntu.
# Run as root.

apt install -y boxes

read -p "Enter the username of the user you would like to run Docker commands without having to prefix with sudo: " THEUSER

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be executed as root, Exiting..."
  exit 1
fi

UBUNTUCODENAME=$( . /etc/os-release && echo "$VERSION_CODENAME" )

echo "Starting Docker & Docker Compose plugin installation" | boxes -d stone -p a2v1

echo "[`date +%m/%d/%Y-%H:%M`] Installing prerequisites"
/usr/bin/apt install -y apt-transport-https ca-certificates curl software-properties-common nfs-common gnupg
ERR=$?
if [ $ERR != 0 ]; then
  THEERROR=$(($THEERROR+$ERR))
  echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred during installing prerequisites"
  exit 1
else
  echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed installing prerequisites"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Adding GPG Key for Official Docker Repository"

# New keyring-based method for Ubuntu 22.04+[web:4][web:13]
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

ERR=$?
if [ $ERR != 0 ]; then
  THEERROR=$(($THEERROR+$ERR))
  echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred adding GPG Key for Official Docker Repository"
  exit 1
else
  echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed adding GPG Key for Official Docker Repository"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Adding Docker repository to APT Sources"

# New repo line with signed-by and codename[web:1][web:4][web:13]
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTUCODENAME stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

ERR=$?
if [ $ERR != 0 ]; then
  THEERROR=$(($THEERROR+$ERR))
  echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred adding Docker repository to APT Sources"
  exit 1
else
  echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed adding Docker repository to APT Sources"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Updating Sources"
/usr/bin/apt update
ERR=$?
if [ $ERR != 0 ]; then
  THEERROR=$(($THEERROR+$ERR))
  echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred updating sources"
  exit 1
else
  echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed updating sources"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Installing Docker Engine and Compose plugin"

# Install Docker Engine + CLI + containerd + Compose v2 plugin[web:1][web:4]
/usr/bin/apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

ERR=$?
if [ $ERR != 0 ]; then
  THEERROR=$(($THEERROR+$ERR))
  echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred installing Docker/Compose plugin"
  exit 1
else
  echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed installing Docker/Compose plugin"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Adding $THEUSER user to docker group"
/usr/sbin/usermod -aG docker "$THEUSER"
ERR=$?
if [ $ERR != 0 ]; then
  THEERROR=$(($THEERROR+$ERR))
  echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, adding $THEUSER user to docker group"
  exit 1
else
  echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed adding $THEUSER user to docker group"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Printing out Docker & Compose version"

docker --version
ERR1=$?
docker compose version
ERR2=$?

if [ $ERR1 != 0 ] || [ $ERR2 != 0 ]; then
  THEERROR=$(($THEERROR+$ERR1+$ERR2))
  echo "[`date +%m/%d/%Y-%H:%M`] ERROR: Docker or Compose version command failed"
  exit 1
else
  echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Docker and Docker Compose plugin installed correctly"
  echo "Use 'docker compose' (with a space) for Compose v2 on Ubuntu $UBUNTUCODENAME."
fi
