#!/bin/bash
#This script is for Ubuntu 18.04 LTS. Ensure you run this script as root

#Update package database
apt update

#Upgrade installation
apt dist-upgrade -y

#Install prerequisites
apt install -y apt-transport-https ca-certificates curl software-properties-common nfs-common

#Add GPGP key for the official Docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#Add Docker repository to APT sources
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

#Update package database
apt update

#Install Docker
apt install docker-ce -y

#Add user to docker group to avoid having to prepend commands with sudo
usermod -aG docker USERNAME