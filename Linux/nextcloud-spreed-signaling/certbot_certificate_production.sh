#!/bin/bash

#Set Font Colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`


#The script below assumes you have a fully installed and updated Ubuntu 18.04 server and you have installed docker and docker-compose

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then
      echo "${RED}This script must be executed as root, Exiting... ${RESET}"
      exit 1
   fi

#Check if /usr/bin/docker exists and if not exit
if [ ! -f "/usr/bin/docker" ]; then
      echo "${RED}Docker does not seem to be installed. Please install Docker and try again. Exiting for now... ${RESET}"
      exit 1
   fi

#Check if /usr/local/bin/docker-compose exists and if not exit
if [ ! -f "/usr/local/bin/docker-compose" ]; then
      echo "${RED}Docker Compose does not seem to be installed. Please install Docker Compose and try again. Exiting for now... ${RESET}"
      exit 1
   fi

#GET INPUTS
echo "Certbot Certificate Production" | boxes -d stone -p a2v1

PS3='Ensure that both ports 80/TCP and 443/TCP are Internet accessible and the Signal FQDN you are going to use is pointing to the public IP address of this machine. Do you wish to continue?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "Starting Certbot Certificate Production"

          
          break
            ;;
        "No")

            echo "Exiting Certbot Certificate Production";
            exit
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

#=== GET USER INPUTS STARTS HERE ===

read -p "Enter the Nextcloud-Signal Hostname you wish to use (Example: signal):"  SIGNAL_HOSTNAME

if [ -z "$SIGNAL_HOSTNAME" ]
then
      echo "${RED}Nextcloud-Signal Hostname cannot be empty ${RESET}"
      exit
fi

#Export the variable
export SIGNAL_HOSTNAME

read -p "Enter the Nextcloud-Signal Domain you wish to use (Example: domain.tld):"  SIGNAL_DOMAIN

if [ -z "$SIGNAL_DOMAIN" ]
then
   
      echo "${RED}Nextcloud-Signal Domain cannot be empty ${RESET}"
      exit
fi

#Export the variable
export SIGNAL_DOMAIN

echo "Requesting Certbot Certificate Production"

cd /opt/nextcloud-spreed-signaling && \
/usr/local/bin/docker-compose run --rm  certbot certonly --webroot --webroot-path /var/www/certbot/ -d $SIGNAL_HOSTNAME.$SIGNAL_DOMAIN

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "${RED}Error $THEERROR, occurred Requesting Certbot Certificate Production ${RESET}"
exit 1
else
echo "${GREEN}Done ${RESET}"
fi

echo "Re-configuring Nginx for Certbot Certificate Production and Restarting Nginx Container"

/bin/sed -i -e "s,dummy,live,g" "/opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default" && \
cd /opt/nextcloud-spreed-signaling && \
/usr/local/bin/docker-compose stop nginx && \
/usr/local/bin/docker-compose start nginx


ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "${RED}Error $THEERROR, occurred Re-configuring Nginx for Certbot Certificate Production and Restarting Nginx Container ${RESET}"
exit 1
else
echo "${GREEN}Done ${RESET}"
fi