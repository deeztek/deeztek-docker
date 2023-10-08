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

echo "Starting TOTP Configuration" | boxes -d stone -p a2v1
echo "[`date +%m/%d/%Y-%H:%M`] Starting TOTP Configuration" >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1


read -p "Browse to ${GREEN}https://guacamole.apache.org/releases/${RESET} to get the latest Apache Guacamole version and then enter that version number in order to continue (Example 1.5.1):"  GUACAMOLEVERSION

echo "Downloading and installing guamole-auth-totp-$GUACAMOLEVERSION.jar extension"
echo "[`date +%m/%d/%Y-%H:%M`] Downloading guamole-auth-totp-$GUACAMOLEVERSION.jar extension" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

wget -O $SCRIPTPATH/guacamole-auth-totp-$GUACAMOLEVERSION.tar.gz https://apache.org/dyn/closer.lua/guacamole/$GUACAMOLEVERSION/binary/guacamole-auth-totp-$GUACAMOLEVERSION.tar.gz?action=download && tar -xvzf $SCRIPTPATH/guacamole-auth-totp-$GUACAMOLEVERSION.tar.gz && cp $SCRIPTPATH/guacamole-auth-totp-$GUACAMOLEVERSION/guacamole-auth-totp-$GUACAMOLEVERSION.jar /opt/guacamole/guacamole_home/extensions/ && rm -rf /opt/guacamole/guacamole_home/extensions/.gitkeep

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Downloading and installing guamole-auth-totp-$GUACAMOLEVERSION.jar extension. Continuing installation but you must manually correct error and restart Guacamole ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`]Error Downloading and installing guamole-auth-totp-$GUACAMOLEVERSION.jar extension. Continuing installation but you must manually correct error and restart Guacamole" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
fi


echo "Starting Guacamole Docker Container"
echo "[`date +%m/%d/%Y-%H:%M`] Starting Guacamole Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

cd /opt/guacamole && /usr/local/bin/docker-compose up -d

            # *** HACKY FIX FOR POSTGRESQL BELOW NO LONGER USED SINCE WE ARE USING MYSQL. LEFT FOR REFERENCE ***
            #cd /opt/guacamole && /usr/local/bin/docker-compose up -d && /usr/local/bin/docker-compose down && /bin/cp $SCRIPTPATH/dbfix/pg_hba.conf /opt/guacamole/dbdata/ && /usr/local/bin/docker-compose up -d

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Starting Guacamole Docker Container. You must manually correct error and restart Guacamole ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Starting Guacamole Docker Container. You must manually correct error and restart Guacamole" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
fi

echo "FINISHED INSTALLATION. ENSURE GUACAMOLE DOCKER CONTAINER IS UP AND RUNNING" | boxes -d stone -p a2v1
echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE GUACAMOLE DOCKER CONTAINER IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
echo "Access Guacamole by navigating with your web browser to https://$ACME_HOSTNAME.$ACME_DOMAIN"  | boxes -d stone -p a2v1

