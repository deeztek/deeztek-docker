#!/bin/bash

#The script below assumes you have a fully installed and updated Ubuntu 18.04 server and you have installed docker and docker-compose

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then
      echo "This script must be executed as root, Exiting..."
      exit 1
   fi

#Check if /usr/bin/docker exists and if not exit
if [ ! -f "/usr/bin/docker" ]; then
      echo "Docker does not seem to be installed. Please install Docker and try again. Exiting for now..."
      exit 1
   fi

#Check if /usr/local/bin/docker-compose exists and if not exit
if [ ! -f "/usr/local/bin/docker-compose" ]; then
      echo "Docker Compose does not seem to be installed. Please install Docker Compose and try again. Exiting for now..."
      exit 1
   fi

#Check if /opt/traefik exists and if not create it
if [ ! -d "/opt/traefik" ]; then
      /bin/mkdir -p /opt/traefik
      echo "/opt/traefk directory does not exist. Creating...."
   fi

#Check if /opt/traefik exists and if not exit
if [ ! -d "/opt/traefik" ]; then
      echo "The /opt/traefik directory does not exist even after attempting to create automatically. Exiting for now..."
      exit 1
   fi

echo "Installing pre-requisite package boxes and apache2-utils"
#Install boxes and apche2-utils
/usr/bin/apt install boxes -y && \
/usr/bin/apt install apache2-utils -y

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi

echo "Creating pre-requisite directories files and setting permissions"
#Create necessary directories and files
/bin/mkdir -p /opt/traefik/data
/usr/bin/touch /opt/traefik/data/acme.json
/bin/chmod 600 /opt/traefik/data/acme.json
/bin/mkdir -p /opt/traefik/logs
/usr/bin/touch /opt/traefik/logs/traefik.log


if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi

#Set the script path
SCRIPTPATH=$(pwd)

#Set install_log Date/Time Stamp
TIMESTAMP=`date +%m-%d-%Y-%H%M`

#GET INPUTS
echo "Traefik Installation" | boxes -d stone -p a2v1
echo "During installation a $SCRIPTPATH/install_log-$TIMESTAMP.log log file will be created. It's highly recommended that you open a separate shell window and tail that file in order to view progress of the installation and/or any errors that may occur. Additionally, ensure that you note all the usernames and passwords you will be prompted to create"

while true; do
    read -p "Do you wish to continue the installation of Traefik? (Enter y or Y. Warning!! Entering n or N will exit this script and the installation will stop!)" yn
    case $yn in
        [Yy]* ) echo "[`date +%m/%d/%Y-%H:%M`] Starting Traefik Installation. View progress at $SCRIPTPATH/install_log-$TIMESTAMP.log" >> $SCRIPTPATH/install_log-$TIMESTAMP.log; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

read -p "Enter the email address to be used for Lets Encrypt Certificate Requests:"  ACME_EMAIL
read -p "Enter the host name to be used for the Traefik container (Example: traefik):"  ACME_HOSTNAME
read -p "Enter the subdomain to be used for Lets Encrypt certificate Requests:"  ACME_DOMAIN
read -p "Enter a username to be used for Traefik Dashboard Authentication:"  TRAEFIK_USERNAME
read -p "Enter a password to be used for Traefik Dashboard Authentication (Ensure you do NOT use $ , single or double quote special characters to form your password):" TRAEFIK_PASSWORD
read -p "Enter the docker network name to be used for Traefik (Example: proxy):" TRAEFIK_NETWORK

echo "Creating README.md file"
#CREATE /OPT/TRAEFIK/README.md FILE
/bin/cp $SCRIPTPATH/README.md /opt/traefik/README.md

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi

echo "Creating /opt/traefik/data/traefik_conf.yaml file"
#CREATE /OPT/TRAEFIK/DATA/TRAEFIK_CONF.YAML FILE
/bin/cp $SCRIPTPATH/templates/traefik-conf-template.yaml /opt/traefik/data/traefik_conf.yaml

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi

echo "Creating /opt/traefik/docker-compose.yml file"
#CREATE /OPT/TRAEFIK/DOCKER-COMPOSE.YML FILE
/bin/cp $SCRIPTPATH/templates/traefik-docker-compose-template.yml /opt/traefik/docker-compose.yml

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi

echo "Configuring /opt/traefik/docker-compose.yml file with Lets Encrypt Email Address"
#REPLACE ALL INSTANCES OF ACME-EMIAIL WITH ACME_EMAIL VARIABLE
/bin/sed -i -e "s,ACME-EMAIL,${ACME_EMAIL},g" "/opt/traefik/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi

echo "Configuring /opt/traefik/docker-compose.yml file with Traefik Network Name"
#REPLACE ALL INSTANCES OF TRAEFIK-NETWORK WITH TRAEFIK_NETWORK VARIABLE
/bin/sed -i -e "s/TRAEFIK-NETWORK/$TRAEFIK_NETWORK/g" "/opt/traefik/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi

echo "Configuring /opt/traefik/docker-compose.yml file with Traefik Host Name"
#REPLACE ALL INSTANCES OF ACME-HOSTNAME WITH ACME_HOSTNAME VARIABLE
/bin/sed -i -e "s/ACME-HOSTNAME/$ACME_HOSTNAME/g" "/opt/traefik/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi

echo "Configuring /opt/traefik/docker-compose.yml file with Lets Encrypt Subdomain"
#REPLACE ALL INSTANCES OF ACME-DOMAIN WITH ACME_DOMAIN VARIABLE
/bin/sed -i -e "s/ACME-DOMAIN/$ACME_DOMAIN/g" "/opt/traefik/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi

echo "Configuring /opt/traefik/docker-compose.yml file with Traefik Dashboard Credentials"

#CREATE TEMP /TMP/CREDSFILE SET TRAEFIK_CREDENTIALS VARIABLE
/bin/echo $(htpasswd -nbB $TRAEFIK_USERNAME "$TRAEFIK_PASSWORD") | sed -e s/\\$/\\$\\$/g >> /tmp/credsfile && \
TRAEFIK_CREDENTIALS=$(</tmp/credsfile) && \

#REPLACE ALL INSTANCES OF TRAEFIK-CREDENTIALS WITH TRAEFIK_CREDENTIALS VARIABLE
/bin/sed -i -e "s,TRAEFIK-CREDENTIALS,${TRAEFIK_CREDENTIALS},g" "/opt/traefik/docker-compose.yml" && \

#DELETE TEMP /TMP/CREDSFILE
/bin/rm -rf /tmp/credsfile

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi


echo "Creating Traefik Docker Network"
#Create TRAEFIK_NETWORK
/usr/bin/docker network create $TRAEFIK_NETWORK

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Warning while creating Docker Network. Either Docker Network Already exists or a system error occurred"
        #exit
fi

echo "Starting Traefik Docker Container"
#Start Traefik Docker Container
cd /opt/traefik && /usr/local/bin/docker-compose up -d

if [ $? -eq 0 ]; then
    echo "Done"
else
        echo "Error occured. Stopped processing!"
        exit
fi

echo "FINISHED INSTALLATION. ENSURE TRAEFIK DOCKER CONTAINER IS UP AND RUNNING" | boxes -d stone -p a2v1
echo "Access Traefik Dashboard by navigating with your web browser to https://$ACME_HOSTNAME.$ACME_DOMAIN"









