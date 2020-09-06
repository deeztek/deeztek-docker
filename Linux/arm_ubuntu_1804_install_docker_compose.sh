#!/bin/bash

#This script will install Docker and Docker Compose on your ARM 64 Ubuntu 18.04 machine. Ensure your Ubuntu installation has all the latest updates.

#Make this script executable:
#chmod +x arm_ubuntu_1804_docker_compose.sh

#Run the script as root:
#./arm_ubuntu_1804_docker_compose.sh OR bash arm_ubuntu_1804_docker_compose.sh

#Enter the username of the user you would like to be able to run Docker commands without having to prefix with sudo when prompted.

#Ensure architecture is ARM 64
if [[ ! `uname -m` =~ "aarch64" ]]; then
      echo "This script is only for the ARM 64 architecture. If you wish to install Docker on x86_64 architecture you must use the ubuntu_1804_docker_compose.sh script instead"
      exit 1
   fi

#Install boxes
apt install -y boxes

#Get Inputs
read -p "Enter the username of the user you would like to run Docker commands without having to prefix with sudo:"  THEUSER

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then
      echo "This script must be executed as root, Exiting..."
      exit 1
   fi

echo "Starting Docker and Docker Compose Installation for ARM Architecture" | boxes -d stone -p a2v1

echo "[`date +%m/%d/%Y-%H:%M`] Installing prerequisites" 

#Install Prerequisites
/usr/bin/apt install -y apt-transport-https ca-certificates curl software-properties-common curl nfs-common libffi-dev libssl-dev python3-dev python3 python3-pip

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred during installing prerequisites"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed installing prerequisites"
fi


echo "[`date +%m/%d/%Y-%H:%M`] Installing Docker"

#Install Docker
/usr/bin/curl -sSL https://get.docker.com | sh

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred installing Docker"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed installing Docker"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Adding $THEUSER user to docker group"

#Add user to docker group
/usr/sbin/usermod -aG docker $THEUSER

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, adding $THEUSER user to docker group"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed adding $THEUSER user to docker group"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Installing Docker Compose using PIP"

#Install Docker Compose Using PIP
sudo pip3 install docker-compose

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, installing Docker Compose"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Installing Docker Compose"
fi
