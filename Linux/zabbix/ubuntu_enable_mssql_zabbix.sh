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


source "$(pwd)/spinner.sh"

# test success
start_spinner 'sleeping for 2 secs...'
sleep 2
stop_spinner $?

echo "Starting Enable MSSQL Support In Zabbix" | boxes -d stone -p a2v1
echo "[`date +%m/%d/%Y-%H:%M`] Starting Enable MSSQL Support In Zabbix" >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1


read -p "Enter DSN Name you wish to use with no spaces or special characters:"  DSN_NAME

if [ -z "$DSN_NAME" ]
then
 
      echo "${RED}DSN Name cannot be empty. ${RESET}"
      exit
   
fi

read -p "Enter MSSQL Server FQDN or IP Address or if you are utilizing named instances, enter SERVER\INSTANCE:"  MSSQL_SERVER

if [ -z "$MSSQL_SERVER" ]
then
         echo "${RED}MSSQL Server cannot be empty. ${RESET}"
      exit
fi

read -p "Enter MSQL Server Port Number (Ex: 1433):"  MSSQL_PORT

if [ -z "$MSSQL_PORT" ]
then
      echo "${RED}MSSQL Server Port Number cannot be empty. ${RESET}"
      exit
fi


echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating docker-compose.yml file...'
sleep 1

/bin/cp $SCRIPTPATH/templates/zabbix-docker-compose-template-mssql.yml /opt/zabbix-docker/docker-compose.yml >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating Dockerfile" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating Dockerfile...'
sleep 1

/bin/cp $SCRIPTPATH/templates/Dockerfile-template /opt/zabbix-docker/Dockerfile >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/zabbix-docker/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating /opt/zabbix-docker/.env file...'
sleep 1

/bin/cp -r $SCRIPTPATH/templates/.env-template /opt/zabbix-docker/.env >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/zabbix-docker/odbc/odbc.ini file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating /opt/zabbix-docker/odbc/odbc.ini file...'
sleep 1

/bin/cp -r $SCRIPTPATH/templates/odbc-template.ini /opt/zabbix-docker/odbc/odbc.ini >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/.env file with Zabbix Host Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/.env file with Zabbix Host Name...'
sleep 1

/bin/sed -i -e "s,ACMEHOSTNAME,${ACME_HOSTNAME},g" "/opt/zabbix-docker/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/.env file with Zabbix Subdomain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/.env file with Zabbix Subdomain...'
sleep 1

/bin/sed -i -e "s/ACMEDOMAIN/${ACME_DOMAIN}/g" "/opt/zabbix-docker/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring Configuring /opt/zabbix-docker/.env file with Zabbix MySQL root password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring Configuring /opt/zabbix-docker/.env file with Zabbix MySQL root password...'
sleep 1

/bin/sed -i -e "s/MYSQLROOTPASSWORD/${MYSQL_ROOT_PASSWORD}/g" "/opt/zabbix-docker/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/.env file with Zabbix MySQL database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/.envfile with Zabbix MySQL database Username...'
sleep 1

/bin/sed -i -e "s/MYSQLUSER/${MYSQL_USER}/g" "/opt/zabbix-docker/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/.env file with Zabbix MySQL database password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/.env file with Zabbix MySQL database password...'
sleep 1


/bin/sed -i -e "s/MYSQLPASSWORD/${MYSQL_PASSWORD}/g" "/opt/zabbix-docker/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/.env file with Zabbix MySQL database name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/.env file with Zabbix MySQL database name...'
sleep 1


/bin/sed -i -e "s/MYSQL_DATABASE/${MYSQL_DATABASE}/g" "/opt/zabbix-docker/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/docker-compose.yml file with network name of Traefik container...'
sleep 1

/bin/sed -i -e "s,TRAEFIKNETWORK,${TRAEFIK_NETWORK},g" "/opt/zabbix-docker/docker-compose.yml" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/odbc/odbc.ini file with MSSQL DSN Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/odbc/odbc.ini file with MSSQL DSN Name...'
sleep 1

/bin/sed -i -e "s,DSNNAME,${DSN_NAME},g" "/opt/zabbix-docker/odbc/odbc.ini" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/odbc/odbc.ini file with MSSQL Server Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/odbc/odbc.ini file with MSSQL MSSQL Server Name...'
sleep 1

/bin/sed -i -e "s,MSSQLSERVER,${MSSQL_SERVER},g" "/opt/zabbix-docker/odbc/odbc.ini" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/odbc/odbc.ini file with MSSQL Server Port" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/odbc/odbc.ini file with MSSQL MSSQL Server Port...'
sleep 1

/bin/sed -i -e "s,MSSQLPORT,${MSSQL_PORT},g" "/opt/zabbix-docker/odbc/odbc.ini" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Building MSSQL Server Support and Starting Zabbix Docker Stack..." >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Building MSSQL Server Support and Starting Zabbix Docker Stack...'
sleep 1

cd /opt/zabbix-docker && /usr/local/bin/docker-compose up -d --build >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "FINISHED INSTALLATION. ENSURE ZABBIX DOCKER STACK IS UP AND RUNNING" | boxes -d stone -p a2v1
echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE ZABBIX DOCKER STACK IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
echo "Access Zabbix by navigating with your web browser to https://$ACME_HOSTNAME.$ACME_DOMAIN and login with default credentials of Admin/zabbix"  | boxes -d stone -p a2v1


