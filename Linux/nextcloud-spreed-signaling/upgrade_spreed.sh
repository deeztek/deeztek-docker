#!/bin/bash

echo "[`date +%m/%d/%Y-%H:%M`] Stopping Nextcloud-Signal Docker Containers"

start_spinner 'Stopping Nextcloud-Signal Docker Containers...'
sleep 1

cd /opt/nextcloud-spreed-signaling && docker-compose down

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Git cloning nextcloud-spreed-signaling to /opt/nextcloud-spreed-signaling..."

start_spinner 'Git cloning nextcloud-spreed-signaling to /opt/nextcloud-spreed-signaling...'
sleep 1

cd /opt/nextcloud-spreed-signaling && git remote add origin https://github.com/strukturag/nextcloud-spreed-signaling.git && git pull origin master

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Building Nextcloud-Signal Docker Containers"

start_spinner 'Building Nextcloud-Signal Docker Containers...'
sleep 1

cd /opt/nextcloud-spreed-signaling && docker-compose build >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Starting Nextcloud-Signal Docker Containers"
start_spinner 'Starting Nextcloud-Signal Docker Containers...'
sleep 1

cd /opt/nextcloud-spreed-signaling && docker-compose up -d >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "FINISHED UPGRADE. ENSURE ALL CONTAINERS ARE UP AND RUNNING" | boxes -d stone -p a2v1

