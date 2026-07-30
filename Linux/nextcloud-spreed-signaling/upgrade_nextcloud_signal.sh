#!/bin/bash

BASE=/opt/nextcloud-spreed-signaling

#Resolve this script's own directory so it can be run from any working
#directory. common.sh and spinner.sh are read relative to it, and the upgrade
#log is written into it.
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#Shared helpers: banner, set_colours
source "$SCRIPTPATH/common.sh"

#Set Font Colors
set_colours

#Set upgrade_log Date/Time Stamp
TIMESTAMP=`date +%m-%d-%Y-%H%M`

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then
      echo "${RED}This script must be executed as root, Exiting... ${RESET}"
      exit 1
   fi

#Check if docker exists and if not exit
if ! command -v docker > /dev/null 2>&1; then
      echo "${RED}Docker does not seem to be installed. Exiting for now... ${RESET}"
      exit 1
   fi

#Check if the docker compose plugin exists and if not exit
if ! docker compose version > /dev/null 2>&1; then
      echo "${RED}The docker compose plugin does not seem to be installed. Exiting for now... ${RESET}"
      exit 1
   fi

#Check the installation directory exists
if [ ! -d "$BASE" ]; then
      echo "${RED}$BASE does not exist. Run install_nextcloud_signal.sh first. Exiting... ${RESET}"
      exit 1
   fi

source "$SCRIPTPATH/spinner.sh"

echo "Nextcloud-Signal Upgrade" | banner

#=== GET USER INPUTS STARTS HERE ===

CURRENT_VERSION=`cd $BASE && git describe --tags 2>/dev/null`

echo "Currently checked out: ${GREEN}${CURRENT_VERSION:-unknown} ${RESET}"
echo "Releases are listed at https://github.com/strukturag/nextcloud-spreed-signaling/releases"
echo ""

read -p "Enter the version to upgrade to (Example: v2.1.1):"  SIGNAL_VERSION

if [ -z "$SIGNAL_VERSION" ]
then
      echo "${RED}Version cannot be empty ${RESET}"
      exit 1
fi

#=== GET USER INPUTS ENDS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Starting upgrade to $SIGNAL_VERSION. View progress at $SCRIPTPATH/upgrade_log-$TIMESTAMP.log" | banner

echo "[`date +%m/%d/%Y-%H:%M`] Stopping Nextcloud-Signal Docker Containers" >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

start_spinner 'Stopping Nextcloud-Signal Docker Containers...'
sleep 1

cd $BASE && docker compose down >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Checking out $SIGNAL_VERSION" >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

start_spinner "Checking out $SIGNAL_VERSION..."
sleep 1

#The local server.conf, .env, docker-compose.yml, nginx/, certbot/, coturn/,
#scripts/ and ofelia/ are listed in .git/info/exclude, which is untracked, so a
#checkout leaves them alone and cannot conflict with them.
cd $BASE && git fetch origin --tags >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1 && \
git checkout $SIGNAL_VERSION >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Updating signaling server image tag in docker-compose.yml" >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

start_spinner 'Updating signaling server image tag in docker-compose.yml...'
sleep 1

#Strip the leading "v" from the tag; the docker image tags are unprefixed
IMAGE_TAG=${SIGNAL_VERSION#v}

sed -i -E "s,(image: strukturag/nextcloud-spreed-signaling:).*,\1${IMAGE_TAG}," "$BASE/docker-compose.yml" >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Rebuilding Janus Docker Image. This takes several minutes." >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

start_spinner 'Rebuilding Janus Docker Image (this takes several minutes)...'
sleep 1

cd $BASE && docker compose build >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Pulling Nextcloud-Signal Docker Images" >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

start_spinner 'Pulling Nextcloud-Signal Docker Images...'
sleep 1

cd $BASE && docker compose pull --ignore-buildable >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Starting Nextcloud-Signal Docker Containers" >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

start_spinner 'Starting Nextcloud-Signal Docker Containers...'
sleep 1

cd $BASE && docker compose up -d >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "FINISHED UPGRADE TO $SIGNAL_VERSION. ENSURE ALL CONTAINERS ARE UP AND RUNNING" | banner

echo "[`date +%m/%d/%Y-%H:%M`] FINISHED UPGRADE TO $SIGNAL_VERSION" >> $SCRIPTPATH/upgrade_log-$TIMESTAMP.log 2>&1
