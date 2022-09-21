#!/bin/bash

#Set Font Colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`

#The script below assumes you have a fully installed and updated Ubuntu 20.04 server and you have installed docker and docker-compose and traefik

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

#Check if docker-compose version is 2.xx 
DOCKERCOMPOSEVER=`docker-compose -v | awk '{print $3}'`
echo "$DOCKERCOMPOSEVER"


if [[ $DOCKERCOMPOSEVER == *"1."* ]]; then
   echo "${RED}Docker Compose must be version 2.xx or higher. Exiting for now... ${RESET}"
  exit 1

fi


echo "Installing Boxes Prerequisite"
#Install boxes and apache2-utils
apt-get install boxes -y > /dev/null 2>&1

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "${RED}Error $THEERROR, occurred Installing Boxes Prerequisite ${RESET}"
exit 1
else
echo "${GREEN}[DONE] ${RESET}"
fi

echo "Installing Git Prerequisite"
#Install boxes and apache2-utils
apt-get install git -y > /dev/null 2>&1

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "${RED}Error $THEERROR, occurred Installing Boxes Prerequisite ${RESET}"
exit 1
else
echo "${GREEN}[DONE] ${RESET}"
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
echo "${GREEN}[DONE] ${RESET}"
fi


#=== GET USER INPUTS STARTS HERE ===

echo "Zabbix Installation" | boxes -d stone -p a2v1

PS3='Do you wish to continue the installation of Zabbix?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "[`date +%m/%d/%Y-%H:%M`] Starting Zabbix Installation." >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1

            echo "Starting Zabbix Installation. View progress at $SCRIPTPATH/install_log-$TIMESTAMP.log" | boxes -d stone -p a2v1

          break
            ;;
        "No")

            echo "Exiting Zabbix installation";
            exit
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

read -p "Enter the Zabbix MySQL root password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your password):"  MYSQL_ROOT

if [ -z "$MYSQL_ROOT" ]
then
      echo "${RED}Zabbix MySQL root password cannot be empty ${RESET}"
      exit
fi

export MYSQL_ROOT


read -p "Enter the Zabbix MySQL database username you wish to use (Example: zabbix):"  MYSQL_USERNAME

if [ -z "$MYSQL_USERNAME" ]
then
      echo "${RED}Zabbix MySQL database username cannot be empty ${RESET}"
      exit
fi

export MYSQL_USERNAME

read -p "Enter the Zabbix MySQL database password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your password):"  MYSQL_PASSWORD

if [ -z "$MYSQL_PASSWORD" ]
then

      echo "${RED}Zabbix MySQL database password cannot be empty ${RESET}"
      exit
fi

export MYSQL_PASSWORD


read -p "Enter the Zabbix hostname you wish to use (Example: Zabbix):"  ACME_HOSTNAME

if [ -z "$ACME_HOSTNAME" ]
then
      echo "${RED}Zabbix hostname cannot be empty ${RESET}"
      exit
fi

#Export the variable
export ACME_HOSTNAME

read -p "Enter the Zabbix subdomain you wish to use (Example: domain.tld):"  ACME_DOMAIN

if [ -z "$ACME_DOMAIN" ]
then
   
      echo "${RED}Zabbix subdomain cannot be empty ${RESET}"
      exit
fi

#Export the variable
export ACME_DOMAIN

#read -p "Enter the Zabbix Server Name you wish to use (Example: Widgets, Inc Zabbix):"  ZABBIX_SERVER

#if [ -z "$ZABBIX_SERVER" ]
#then

#      echo "${RED}Zabbix Server Name cannot be empty ${RESET}"
#      exit
#fi


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

export TRAEFIK_NETWORK

#=== GET USER INPUTS ENDS HERE ===

#Set the script path
SCRIPTPATH=$(pwd)

export SCRIPTPATH

#Set install_log Date/Time Stamp
TIMESTAMP=`date +%m-%d-%Y-%H%M`

#Export the variable
export TIMESTAMP

source "$(pwd)/spinner.sh"

# test success
start_spinner 'sleeping for 2 secs...'
sleep 2
stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Git cloning zabbix-docker from https://github.com/zabbix/zabbix-docker to /opt/zabbix-docker" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Git cloning zabbix-docker from https://github.com/zabbix/zabbix-docker to /opt/zabbix-docker...'
sleep 1

#git clone zabbix-docker
/usr/bin/git clone https://github.com/zabbix/zabbix-docker.git /opt/zabbix-docker >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#Check if /opt/zabbix-docker exists and if not exit
echo "[`date +%m/%d/%Y-%H:%M`] Checking if /opt/zabbix-docker directory exists" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
echo "Checking if /opt/zabbix-docker directory exists..."
if [ ! -d "/opt/zabbix-docker" ]; then
echo "${RED}The /opt/zabbix-docker directory does not exist. Exiting for now... ${RESET}"
exit 1
else
echo "${GREEN}[DONE] ${RESET}"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Creating pre-requisite directories for Ofelia" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating pre-requisite directories for Ofelia...'
sleep 1

#Create necessary directories and files
/bin/mkdir -p /opt/zabbix-docker/ofelia_config && \
/bin/mkdir -p /opt/zabbix-docker/ofelia_logs >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Creating README.md file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating README.md file...'
sleep 1

/bin/cp $SCRIPTPATH/README.md /opt/zabbix-docker/README.md >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/zabbix-docker/ofelia_config/config.ini" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating /opt/zabbix-docker/ofelia_config/config.ini...'
sleep 1

/bin/cp -r $SCRIPTPATH/ofelia_config/config.ini /opt/zabbix-docker/ofelia_config/config.ini >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


PS3='Do you wish to enable MSSQL Support? '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            /bin/bash $SCRIPTPATH/ubuntu_enable_mssql_zabbix.sh
            exit
            ;;
        "No")
 
            echo "NOT enabling MSSQL Support"
            echo "[`date +%m/%d/%Y-%H:%M`] NOT enabling MSSQL Support" >> $SCRIPTPATH/install_log-$TIMESTAMP.log


echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating docker-compose.yml file...'
sleep 1

/bin/cp $SCRIPTPATH/templates/zabbix-docker-compose-template.yml /opt/zabbix-docker/docker-compose.yml >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/zabbix-docker/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating /opt/zabbix-docker/.env file...'
sleep 1

#create /opt/Zabbix/.env
/bin/cp -r $SCRIPTPATH/templates/.env-template /opt/zabbix-docker/.env >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

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


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/env_vars/.MYSQL_ROOT_PASSWORD file with Zabbix MySQL root password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/env_vars/.MYSQL_ROOT_PASSWORD file with Zabbix MySQL root password...'
sleep 1

/bin/sed -i -e "s,root_pwd,${MYSQL_ROOT},g" "/opt/zabbix-docker/env_vars/.MYSQL_ROOT_PASSWORD" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/env_vars/.MYSQL_USER file with Zabbix MySQL database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/env_vars/.MYSQL_USER file with Zabbix MySQL database Username...'
sleep 1

/bin/sed -i -e "s,zabbix,${MYSQL_USERNAME},g" "/opt/zabbix-docker/env_vars/.MYSQL_USER" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/env_vars/.MYSQL_PASSWORD file with Zabbix MySQL database password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/env_vars/.MYSQL_PASSWORD file with Zabbix MySQL database password...'
sleep 1


/bin/sed -i -e "s,zabbix,${MYSQL_PASSWORD},g" "/opt/zabbix-docker/env_vars/.MYSQL_PASSWORD" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?



echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/zabbix-docker/docker-compose.yml file with network name of Traefik container...'
sleep 1

/bin/sed -i -e "s,TRAEFIKNETWORK,${TRAEFIK_NETWORK},g" "/opt/zabbix-docker/docker-compose.yml" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Starting Zabbix Docker Stack" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Starting Zabbix Docker Stack...'
sleep 1

cd /opt/zabbix-docker && /usr/local/bin/docker-compose up -d >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "FINISHED INSTALLATION. ENSURE ZABBIX DOCKER STACK IS UP AND RUNNING" | boxes -d stone -p a2v1
echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE ZABBIX DOCKER STACK IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
echo "Access Zabbix by navigating with your web browser to https://$ACME_HOSTNAME.$ACME_DOMAIN and login with default credentials of Admin/zabbix"  | boxes -d stone -p a2v1

            exit
            ;;
        
        *) echo "invalid option $REPLY";;
    esac
done














