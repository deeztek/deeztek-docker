#!/bin/bash

BASE=/opt/nextcloud-spreed-signaling

#Resolve this script's own directory so it can be run from any working directory
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#Shared helpers: banner, set_colours
source "$SCRIPTPATH/common.sh"

#Set Font Colors
set_colours

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
echo "Certbot Certificate Staging" | banner

PS3='Ensure that both ports 80/TCP and 443/TCP are Internet accessible and the Signal FQDN you are going to use is pointing to the public IP address of this machine. Do you wish to continue?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "Starting Certbot Certificate Staging"


          break
            ;;
        "No")

            echo "Exiting Certbot Certificate Staging";
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

#The webroot must be the directory nginx serves as /config/www, which is
#$BASE/nginx/conf/www on the host. Paths must be absolute for docker run.
docker run --rm --name certbot \
  -v $BASE/nginx/conf/www:/var/www/certbot \
  -v $BASE/certbot/conf/:/etc/letsencrypt \
  -v $BASE/certbot/logs:/var/log/letsencrypt \
  certbot/certbot:latest certonly --webroot --webroot-path /var/www/certbot/ --dry-run -d $SIGNAL_HOSTNAME.$SIGNAL_DOMAIN

ERR=$?
if [ $ERR != 0 ]; then
echo "${RED}Error $ERR, occurred during the Lets Encrypt staging dry run ${RESET}"
exit 1
else
echo "${GREEN}Done ${RESET}"
fi
