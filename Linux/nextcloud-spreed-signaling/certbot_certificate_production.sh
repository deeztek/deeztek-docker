#!/bin/bash

#Set Font Colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`

BASE=/opt/nextcloud-spreed-signaling

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then
      echo "${RED}This script must be executed as root, Exiting... ${RESET}"
      exit 1
   fi

#Check if docker exists and if not exit
if ! command -v docker > /dev/null 2>&1; then
      echo "${RED}Docker does not seem to be installed. Please install Docker and try again. Exiting for now... ${RESET}"
      exit 1
   fi

#Check the installation directory exists
if [ ! -d "$BASE" ]; then
      echo "${RED}$BASE does not exist. Run install_nextcloud_signal.sh first. Exiting... ${RESET}"
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

#The webroot must be the directory nginx serves as /config/www, which is
#$BASE/nginx/conf/www on the host. Paths must be absolute for docker run.
docker run --rm --name certbot \
  -v $BASE/nginx/conf/www:/var/www/certbot \
  -v $BASE/certbot/conf/:/etc/letsencrypt \
  -v $BASE/certbot/logs:/var/log/letsencrypt \
  certbot/certbot:latest certonly --webroot --webroot-path /var/www/certbot/ -d $SIGNAL_HOSTNAME.$SIGNAL_DOMAIN

ERR=$?
if [ $ERR != 0 ]; then
echo "${RED}Error $ERR, occurred Requesting Certbot Certificate Production ${RESET}"
exit 1
else
echo "${GREEN}Done ${RESET}"
fi

echo "Re-configuring Nginx for Certbot Certificate Production and Restarting Nginx Container"

/bin/sed -i -e "s,/etc/nginx/ssl/dummy/,/etc/nginx/ssl/live/,g" "$BASE/nginx/conf/nginx/site-confs/default.conf" && \
docker container restart nextcloud_spreed_nginx


ERR=$?
if [ $ERR != 0 ]; then
echo "${RED}Error $ERR, occurred Re-configuring Nginx for Certbot Certificate Production and Restarting Nginx Container ${RESET}"
exit 1
else
echo "${GREEN}Done ${RESET}"
fi

echo "Re-configuring Coturn for Certbot Certificate Production and Restarting Coturn Container"

#Copy certificate and private key to coturn
cp $BASE/certbot/conf/live/$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN/fullchain.pem $BASE/coturn/fullchain.pem && \
cp $BASE/certbot/conf/live/$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN/privkey.pem $BASE/coturn/privkey.pem && \

#Set certificate and key permissions. 0755 on the directory so the coturn
#container can traverse it, 0644 on the files themselves. A recursive 0644
#would strip +x from the directory.
chmod 0755 $BASE/coturn && \
chmod 0644 $BASE/coturn/fullchain.pem $BASE/coturn/privkey.pem && \

#Restart Coturn container to load new certificate and key
docker container restart nextcloud_spreed_coturn

ERR=$?
if [ $ERR != 0 ]; then
echo "${RED}Error $ERR, occurred Re-configuring Coturn for Certbot Certificate Production ${RESET}"
exit 1
else
echo "${GREEN}Done ${RESET}"
fi
