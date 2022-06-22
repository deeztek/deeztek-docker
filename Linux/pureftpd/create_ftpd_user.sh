#!/bin/bash

echo "Checking if user executing this script belongs to the docker group..."
if id -nG "$USER" | grep -qw "docker"; then
    echo "Success! This script is executed as a user belonging to the docker group, Proceeding..."
else
    echo "Failed! This script must be executed as a user belonging to the docker group, Exiting..."
     exit 1
fi


read -p "Enter a FTP Username you wish to create: "  FTP_USER

docker exec -it pure-ftpd /usr/bin/pure-pw useradd $FTP_USER -u 33 -g 33 -d /mnt/ftp/ -f /etc/pure-ftpd/passwd/pureftpd.passwd -m
