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

echo "Installing Boxes Prerequisite"
#Install boxes and apache2-utils
apt-get install boxes -y > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Installing Boxes Prerequisite ${RESET}"
        exit 1
fi

echo "Installing Spinner Prerequisite"
#Install spinner
apt-get install spinner -y  > /dev/null 2>&1

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "${RED}Error $THEERROR, occurred Installing Spinner Prerequisite ${RESET}"
exit 1
else
echo "${GREEN}Completed Installing Spinner Prerequisite ${RESET}"
fi


#Set the script path
SCRIPTPATH=$(pwd)

#Set install_log Date/Time Stamp
TIMESTAMP=`date +%m-%d-%Y-%H%M`

#Export the variable
export TIMESTAMP

#GET INPUTS
echo "Collabora Installation" | boxes -d stone -p a2v1

PS3='Do you wish to continue the installation of Collabora?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "[`date +%m/%d/%Y-%H:%M`] Starting Collabora Installation." >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1  | boxes -d stone -p a2v1

            echo "Starting Collabora Installation. View progress at $SCRIPTPATH/install_log-$TIMESTAMP.log" | boxes -d stone -p a2v1

          break
            ;;
        "No")

            echo "Exiting Collabora installation";
            exit
            ;;

        *) echo "invalid option $REPLY";;
    esac
done



read -p "Enter the Collabora Site Name you wish to use with no spaces or special characters (Example: mysite):"  SITE_NAME

if [ -z "$SITE_NAME" ]
then
      echo "${RED}Collabora Site Name cannot be empty ${RESET}"
      exit
fi

#Export the variable
export SITE_NAME



read -p "Enter the Collabora Hostname you wish to use (Example: office):"  COLLABORA_HOSTNAME

if [ -z "$COLLABORA_HOSTNAME" ]
then
      echo "${RED}Collabora Hostname cannot be empty ${RESET}"
      exit
fi

#Export the variable
export COLLABORA_HOSTNAME

read -p "Enter the Collabora Subdomain you wish to use (Example: domain.tld):"  COLLABORA_DOMAIN

if [ -z "$COLLABORA_DOMAIN" ]
then
   
      echo "${RED}Collabora Subdomain cannot be empty ${RESET}"
      exit
fi

#Export the variable
export COLLABORA_DOMAIN

#Output containers and their networks
echo "${GREEN}Below is a listing of your containers and their associated networks.
Locate the Traefik container network name and enter it in the prompt below.
If you are not able to locate the Traefik container, ensure Traefik is configured
and running ${RESET}"

/usr/bin/docker container ls --format 'table {{.Names}}\t{{.Networks}}'  | boxes -d stone -p a2v1


read -p "Enter the network name of your Traefik container from the listing above (Example: proxy):"  TRAEFIK_NETWORK

if [ -z "$TRAEFIK_NETWORK" ]
then
   
      echo "${RED}the network name of your Traefik container cannot be empty ${RESET}"
      exit
fi


#Check if /opt/$SITE_NAME-Collabora exists and if not create it
if [ ! -d "/opt/$SITE_NAME-Collabora" ]; then
      /bin/mkdir -p /opt/$SITE_NAME-Collabora
      echo "/opt/$SITE_NAME-Collabora directory does not exist. Creating...."
   fi

#Check if /opt/$SITE_NAME-Collabora exists and if not exit
if [ ! -d "/opt/$SITE_NAME-Collabora" ]; then
      echo "${RED}The /opt/$SITE_NAME-Collabora directory does not exist even after attempting to create automatically. Exiting for now... ${RESET}"
      exit 1
   fi

source "$(pwd)/spinner.sh"

# test success
start_spinner 'sleeping for 2 secs...'
sleep 2
stop_spinner $?

start_spinner 'Creating docker-compose.yml...'
sleep 1

echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

/bin/cp $SCRIPTPATH/templates/collabora-docker-compose-template.yml /opt/$SITE_NAME-Collabora/docker-compose.yml

stop_spinner $?

start_spinner 'Creating .env file...'
sleep 1

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/$SITE_NAME-Collabora/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

#create /opt/$SITE_NAME-Collabora/.env
/bin/cp -r $SCRIPTPATH/templates/.env-template /opt/$SITE_NAME-Collabora/.env

stop_spinner $?

start_spinner 'Configuring .env file with Collabora Hostname...'
sleep 1

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-Collabora/.env file with Collabora Hostname" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

/bin/sed -i -e "s,COLLABORAHOSTNAME,${COLLABORA_HOSTNAME},g" "/opt/$SITE_NAME-Collabora/.env"

stop_spinner $?

start_spinner 'Configuring .env file with Collabora Subdomain...'
sleep 1


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-Collabora/.env file with Collabora Subdomain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

/bin/sed -i -e "s,COLLABORADOMAIN,${COLLABORA_DOMAIN},g" "/opt/$SITE_NAME-Collabora/.env"

stop_spinner $?

start_spinner 'Creating Random Collabora Username...'
sleep 1

COLLABORA_USERNAME=`/bin/cat /dev/urandom | tr -dc 'a-z0-9' | fold -w ${1:-10} | head -n 1`

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Random Collabora Username is: $COLLABORA_USERNAME" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Random Collabora Username is: $COLLABORA_USERNAME" | boxes -d stone -p a2v1


start_spinner 'Creating Random Collabora Password...'
sleep 1

COLLABORA_PASSWORD=`/bin/cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-20} | head -n 1`

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Random Collabora Password is: $COLLABORA_PASSWORD" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Random Collabora Password is: $COLLABORA_PASSWORD" | boxes -d stone -p a2v1

start_spinner 'Configuring .env file with Collabora Username...'
sleep 1

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-Collabora/.env file with Collabora Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

/bin/sed -i -e "s,COLLABORAUSERNAME,${COLLABORA_USERNAME},g" "/opt/$SITE_NAME-Collabora/.env"

stop_spinner $?

start_spinner 'Configuring .env file with Collabora Password...'
sleep 1

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-Collabora/.env file with Collabora Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

/bin/sed -i -e "s,COLLABORAPASSWORD,${COLLABORA_PASSWORD},g" "/opt/$SITE_NAME-Collabora/.env"

stop_spinner $?

#=== CONFIGURE /opt/$SITE_NAME-Collabora/.env ENDS HERE ===

#=== CONFIGURE /opt/$SITE_NAME-Collabora/docker-compose.yml STARTS HERE ===

start_spinner 'Configuring docker-compose.yml file with with network name of Traefik container...'
sleep 1


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-Collabora/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

/bin/sed -i -e "s,TRAEFIKNETWORK,${TRAEFIK_NETWORK},g" "/opt/$SITE_NAME-Collabora/docker-compose.yml"

stop_spinner $?

start_spinner 'Configuring docker-compose.yml file with Collabora Site Name...'
sleep 1

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-Collabora/docker-compose.yml file with Collabora Site Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

/bin/sed -i -e "s,SITENAME,${SITE_NAME},g" "/opt/$SITE_NAME-Collabora/docker-compose.yml"

stop_spinner $?

#=== CONFIGURE /opt/$SITE_NAME-Collabora/docker-compose.yml ENDS HERE ===

start_spinner 'Starting Collabora Docker Container...'
sleep 1

echo "[`date +%m/%d/%Y-%H:%M`] Starting Collabora Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

cd /opt/$SITE_NAME-Collabora && /usr/local/bin/docker-compose up -d

stop_spinner $?

echo "FINISHED INSTALLATION. ENSURE COLLABORA DOCKER CONTAINER IS UP AND RUNNING" | boxes -d stone -p a2v1

echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE COLLABORA DOCKER CONTAINER IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1
            
echo "Access Collabora by navigating with your web browser to https://$COLLABORA_HOSTNAME.$COLLABORA_DOMAIN"  | boxes -d stone -p a2v1











