#!/bin/bash

# This script installs Docker Engine and the Docker Compose v2 plugin on Ubuntu.
# Run as root.
#
# Ubuntu only. It uses apt and Docker's Ubuntu package repository, so it refuses
# to run anywhere else rather than adding a repository that does not match the
# host.

#Ensure Script is run as root and if not exit
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be executed as root, Exiting..."
  exit 1
fi

#--- Ubuntu check ------------------------------------------------------------
# Refuse to continue on anything that is not Ubuntu. Docker publishes separate
# repositories per distribution, and pointing the Ubuntu one at a Debian, RHEL
# or Fedora host installs packages built for the wrong release.
if [ ! -r /etc/os-release ]; then
  echo "ERROR: /etc/os-release not found, cannot identify this operating system."
  echo "This script supports Ubuntu only. Exiting..."
  exit 1
fi

. /etc/os-release

if [ "$ID" != "ubuntu" ]; then
  echo ""
  echo "############################################################"
  echo "  WARNING: This script supports Ubuntu only."
  echo ""
  echo "  Detected: ${PRETTY_NAME:-$ID}"
  echo ""
  echo "  It installs from Docker's Ubuntu apt repository. Running it"
  echo "  on another distribution would configure a repository that"
  echo "  does not match this host."
  echo ""
  echo "  For other distributions see:"
  echo "    https://docs.docker.com/engine/install/"
  echo "############################################################"
  echo ""
  echo "Exiting..."
  exit 1
fi

# Ubuntu derivatives set VERSION_CODENAME to their own codename but keep the
# upstream one in UBUNTU_CODENAME. Docker's repository is indexed by the Ubuntu
# codename, so prefer that when present.
UBUNTUCODENAME="${UBUNTU_CODENAME:-$VERSION_CODENAME}"

if [ -z "$UBUNTUCODENAME" ]; then
  echo "ERROR: could not determine the Ubuntu release codename. Exiting..."
  exit 1
fi

# Docker publishes packages per architecture; do not assume amd64.
DOCKERARCH="$(dpkg --print-architecture)"

echo "[`date +%m/%d/%Y-%H:%M`] Detected Ubuntu $UBUNTUCODENAME ($DOCKERARCH)"

#--- user to add to the docker group -----------------------------------------
read -p "Enter the username of the user you would like to run Docker commands without having to prefix with sudo: " THEUSER

if [ -z "$THEUSER" ]; then
  echo "ERROR: no username entered. Exiting..."
  exit 1
fi

if ! id "$THEUSER" > /dev/null 2>&1; then
  echo "ERROR: user \"$THEUSER\" does not exist on this host. Exiting..."
  exit 1
fi

echo "[`date +%m/%d/%Y-%H:%M`] Updating package lists"
/usr/bin/apt update
ERR=$?
if [ $ERR != 0 ]; then
  echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred updating package lists"
  exit 1
fi

/usr/bin/apt install -y boxes > /dev/null 2>&1

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

echo "[`date +%m/%d/%Y-%H:%M`] Removing conflicting distribution packages, if present"

# Ubuntu ships its own docker.io, docker-compose and containerd packages. They
# conflict with Docker's official ones, and docker-compose there is the
# unsupported v1 python tool. Removal is expected to be a no-op on a clean host.
/usr/bin/apt remove -y docker.io docker-compose docker-compose-v2 docker-doc podman-docker containerd runc > /dev/null 2>&1

echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed removing conflicting packages"

echo "[`date +%m/%d/%Y-%H:%M`] Adding GPG Key for Official Docker Repository"

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
ERR=$?
if [ $ERR != 0 ]; then
  THEERROR=$(($THEERROR+$ERR))
  echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred adding GPG Key for Official Docker Repository"
  exit 1
fi
chmod a+r /etc/apt/keyrings/docker.gpg

echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed adding GPG Key for Official Docker Repository"

echo "[`date +%m/%d/%Y-%H:%M`] Adding Docker repository to APT Sources"

echo "deb [arch=$DOCKERARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTUCODENAME stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

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

# docker-buildx-plugin is required: "docker compose build" builds through
# BuildKit, so without it any compose file with a build section fails.
/usr/bin/apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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
docker buildx version
ERR3=$?

if [ $ERR1 != 0 ] || [ $ERR2 != 0 ] || [ $ERR3 != 0 ]; then
  THEERROR=$(($THEERROR+$ERR1+$ERR2+$ERR3))
  echo "[`date +%m/%d/%Y-%H:%M`] ERROR: Docker, Compose or Buildx version command failed"
  exit 1
else
  echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Docker, Compose and Buildx plugins installed correctly"
  echo "Use 'docker compose' (with a space) for Compose v2 on Ubuntu $UBUNTUCODENAME."
  echo "$THEUSER must log out and back in before running docker without sudo."
fi
