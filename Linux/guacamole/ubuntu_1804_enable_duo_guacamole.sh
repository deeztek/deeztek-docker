#!/bin/bash

#Set Font Colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then

      echo "${RED}This script must be executed as root, Exiting... ${RESET}"
      exit 1
   fi

#Set the script path
SCRIPTPATH=$(pwd)

echo "Starting Duo MFA Configuration" | boxes -d stone -p a2v1
echo "[`date +%m/%d/%Y-%H:%M`] Starting Duo MFA Configuration" >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1

read -p "Enter DUO API Hostname:"  DUO_API_HOSTNAME

if [ -z "$DUO_API_HOSTNAME" ]
then
 
      echo "${RED}DUO API Hostname cannot be empty. Continuing installation but you must manually correct error and restart Guacamole ${RESET}"
   
fi

read -p "Enter DUO Integration Key:"  DUO_INTEGRATION_KEY

if [ -z "$DUO_INTEGRATION_KEY" ]
then
      echo "${RED}DUO Integration Key cannot be empty. Continuing installation but you must manually correct error and restart Guacamole ${RESET}"
fi

read -p "Enter DUO Secret Key:"  DUO_SECRET_KEY

if [ -z "$DUO_SECRET_KEY" ]
then
      echo "${RED}DUO Secret Key cannot be empty. Continuing installation but you must manually correct error and restart Guacamole ${RESET}"
fi


#CREATE 64 CHARACTER ALPHANUMERIC DUO APPLICATION KEY
DUO_APPLICATION_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)

echo "Creating guacamole_home/guacamole.properties file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating guacamole_home/guacamole.properties file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp $SCRIPTPATH/templates/guacamole.properties-template /opt/guacamole/guacamole_home/guacamole.properties

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating guacamole_home/guacamole.properties file. Continuing installation but you must manually correct error and restart Guacamole ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating guacamole_home/guacamole.properties file. Continuing installation but you must manually correct error and restart Guacamole" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
       
fi

echo "Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO API Hostname"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO API Hostname" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s/DUOAPIHOSTNAME/${DUO_API_HOSTNAME}/g" "/opt/guacamole/guacamole_home/guacamole.properties"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO API Hostname. Continuing installation but you must manually correct error and restart Guacamole ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO API Hostname. Continuing installation but you must manually correct error and restart Guacamole" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
fi

echo "Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Integration Key"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Integration Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s/DUOINTEGRATIONKEY/${DUO_INTEGRATION_KEY}/g" "/opt/guacamole/guacamole_home/guacamole.properties"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Integration Key. Continuing installation but you must manually correct error and restart Guacamole ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Integration Key. Continuing installation but you must manually correct error and restart Guacamole" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
fi

echo "Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Secret Key"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Secret Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s/DUOSECRETKEY/${DUO_SECRET_KEY}/g" "/opt/guacamole/guacamole_home/guacamole.properties"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Secret Key. Continuing installation but you must manually correct error and restart Guacamole ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Secret Key. Continuing installation but you must manually correct error and restart Guacamole" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
fi

echo "Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Application Key"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Application Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s/DUOAPPLICATIONKEY/${DUO_APPLICATION_KEY}/g" "/opt/guacamole/guacamole_home/guacamole.properties"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Application Key. Continuing installation but you must manually correct error and restart Guacamole ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/guacamole/guacamole_home/guacamole.properties file with DUO Application Key. Continuing installation but you must manually correct error and restart Guacamole" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
fi

echo "Enabling DUO MFA in Guacamole docker-compose.yml"
echo "[`date +%m/%d/%Y-%H:%M`] Enabling DUO MFA in Guacamole docker-compose.yml" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i '/GUACAMOLE_HOME/s/^#//g' /opt/guacamole/docker-compose.yml

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Enabling DUO MFA in Guacamole docker-compose.yml. Continuing installation but you must manually correct error and restart Guacamole ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Enabling DUO MFA in Guacamole docker-compose.yml. Continuing installation but you must manually correct error and restart Guacamole" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
fi

echo "Starting Guacamole Docker Container"
echo "[`date +%m/%d/%Y-%H:%M`] Starting Guacamole Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

cd /opt/guacamole && /usr/local/bin/docker-compose up -d && /usr/local/bin/docker-compose down && /bin/cp $SCRIPTPATH/deeztek-docker/Linux/guacamole/dbfix/pg_hba.conf /opt/guacamole/dbdata/ && /usr/local/bin/docker-compose up -d

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Starting Guacamole Docker Container. You must manually correct error and restart Guacamole ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Starting Guacamole Docker Container. You must manually correct error and restart Guacamole" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
fi

echo "FINISHED INSTALLATION. ENSURE GUACAMOLE DOCKER CONTAINER IS UP AND RUNNING" | boxes -d stone -p a2v1
echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE GUACAMOLE DOCKER CONTAINER IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
echo "Access Guacamole by navigating with your web browser to https://$ACME_HOSTNAME.$ACME_DOMAIN"  | boxes -d stone -p a2v1

