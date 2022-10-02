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

#Ensure Ubuntu 18.04 or 20.04 and if not exit
if ! [[ "18.04 20.04" == *"$(lsb_release -rs)"* ]];
then
    echo "Ubuntu $(lsb_release -rs) is not currently supported.";
    exit;
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
DOCKERCOMPOSEVER=`docker-compose -v | awk '{print $4}'`

if [[ $DOCKERCOMPOSEVER == *"v1."* ]]; then
   echo "${RED}Docker Compose must be version 2.xx or higher. Exiting for now... ${RESET}"
  exit 1

else
echo "${GREEN}Found Docker Compose $DOCKERCOMPOSEVER Proceeding... ${RESET}"

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


#=== GET USER INPUTS STARTS HERE ===

echo "Authentik Installation" | boxes -d stone -p a2v1

PS3='Do you wish to continue the installation of Authentik?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "[`date +%m/%d/%Y-%H:%M`] Starting Authentik Installation." >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1

            echo "Starting Authentik Installation. View progress at $SCRIPTPATH/install_log-$TIMESTAMP.log" | boxes -d stone -p a2v1

          break
            ;;
        "No")

            echo "Exiting Authentik installation";
            exit
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

read -p "Enter the Authentik Hostname you wish to use (Ex: sso):"  AUTHENTIK_HOST

if [ -z "$AUTHENTIK_HOST" ]
then
      echo "${RED}The Authentik Hostname cannot be empty ${RESET}"
      exit
fi

export AUTHENTIK_HOST

read -p "Enter the Authentik domain you wish to use (Ex: domain.tld):"  AUTHENTIK_DOMAIN

if [ -z "$AUTHENTIK_DOMAIN" ]
then
      echo "${RED}The Authentik domain cannot be empty ${RESET}"
      exit
fi

export AUTHENTIK_DOMAIN


read -p "Enter the Authentik Postgres Database Name you with to use (Example: authentik_db):"  POSTGRES_DB

if [ -z "$POSTGRES_DB" ]
then
      echo "${RED}The Authentik Postgres Database Name cannot be empty ${RESET}"
      exit
fi

export POSTGRES_DB

read -p "Enter the Authentik Postgres Database Username you with to use (Example: authentik):"  POSTGRES_USER

if [ -z "$POSTGRES_USER" ]
then
      echo "${RED}The Authentik Postgres Database Username cannot be empty ${RESET}"
      exit
fi

export POSTGRES_USER

read -p "Enter the Authentik Postgres Database Password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your password):"  POSTGRES_PASSWORD

if [ -z "$POSTGRES_PASSWORD" ]
then

      echo "${RED}The Authentik Postgres Database Password cannot be empty ${RESET}"
      exit
fi

export POSTGRES_PASSWORD

read -p "Enter your GeoIP Account ID:"  GEOIPUPDATE_ACCOUNT_ID

if [ -z "$GEOIPUPDATE_ACCOUNT_ID" ]
then

      echo "${RED}The GeoIP Account ID cannot be empty ${RESET}"
      exit
fi

export GEOIPUPDATE_ACCOUNT_ID

read -p "Enter your GeoIP License Key:"  GEOIPUPDATE_LICENSE_KEY

if [ -z "$GEOIPUPDATE_LICENSE_KEY" ]
then

      echo "${RED}The GeoIP License Key cannot be empty ${RESET}"
      exit
fi

export GEOIPUPDATE_LICENSE_KEY


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

read -p "Enter the full path to an EXISTING directory where your Authentik Data will reside without an ending slash / (Example: /mnt/data):"  AUTHENTIK_DATA_PATH

if [ -z "$AUTHENTIK_DATA_PATH" ]
then
   
      echo "${RED}Authentik Data Path cannot be empty ${RESET}"
      exit
fi

#Export the variable
export AUTHENTIK_DATA_PATH

#=== GET USER INPUTS ENDS HERE ===

#=== CREATING DATA DIRECTORIES STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Creating Authentik Data directories and setting permissions in $AUTHENTIK_DATA_PATH" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

echo "Creating Authentik Data directories and setting permissions in $AUTHENTIK_DATA_PATH"

#Create necessary directories and setting permissions
/bin/mkdir -p /opt/authentik && \
/bin/mkdir -p $AUTHENTIK_DATA_PATH/database && \
/bin/mkdir -p $AUTHENTIK_DATA_PATH/redis && \
/bin/mkdir -p $AUTHENTIK_DATA_PATH/media && \
/bin/mkdir -p $AUTHENTIK_DATA_PATH/custom-templates && \
/bin/mkdir -p $AUTHENTIK_DATA_PATH/geoip  && \
/bin/chown -R $PUID:$PGID $AUTHENTIK_DATA_PATH/ 2>> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

if [ $? -eq 0 ]; then
    echo "${GREEN}[DONE] ${RESET}"
else
        echo "${RED}Error Creating Authentik Data directories and setting permissions. Ensure the directory exists and that you have access to it $AUTHENTIK_DATA_PATH ${RESET}"
        exit 1
fi

#=== CREATING DATA DIRECTORIES ENDS HERE ===


#=== GENERATING VARIABLES STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Generating Random Authentik Secret Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Random Authentik Secret Key...'
sleep 1

AUTHENTIK_SECRET_KEY=`/usr/bin/openssl rand -hex 50` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Authentik Secret Key is: $AUTHENTIK_SECRET_KEY" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Authentik Secret Key is:${GREEN} $AUTHENTIK_SECRET_KEY ${RESET}" | boxes -d stone -p a2v1

#Export the variable
export AUTHENTIK_SECRET_KEY

#=== GENERATING VARIABLES ENDS HERE ===


#Check if /opt/authentik exists and if not exit
echo "[`date +%m/%d/%Y-%H:%M`] Checking if /opt/authentik directory exists" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
echo "Checking if /opt/authentik directory exists..."
if [ ! -d "/opt/authentik" ]; then
echo "${RED}The /opt/authentik directory does not exist. Exiting for now... ${RESET}"
exit 1
else
echo "${GREEN}[DONE] ${RESET}"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Creating pre-requisite directories for Ofelia" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating pre-requisite directories for Ofelia...'
sleep 1

#Create necessary directories and files
/bin/mkdir -p /opt/authentik/ofelia_config && \
/bin/mkdir -p /opt/authentik/ofelia_logs >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#OFELIA CONFIG DISABLED FOR BELOW

#echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/authentik/ofelia_config/config.ini" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

#start_spinner 'Creating /opt/authentik/ofelia_config/config.ini...'
#sleep 1

#/bin/cp -r $SCRIPTPATH/ofelia_config/config.ini /opt/authentik/ofelia_config/config.ini >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

#stop_spinner $?

#OFELIA CONFIG DISABLED FOR NOW ABOVE


echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating docker-compose.yml file...'
sleep 1

/bin/cp $SCRIPTPATH/templates/docker-compose-template.yml /opt/authentik/docker-compose.yml >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose-override-template.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating docker-compose-override-template.yml file...'
sleep 1

/bin/cp $SCRIPTPATH/templates/docker-compose-override-template.yml /opt/authentik/docker-compose-overrride.yml >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/authentik/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating /opt/authentik/.env file...'
sleep 1

#create /opt/Zabbix/.env
/bin/cp -r $SCRIPTPATH/templates/.env-template /opt/authentik/.env >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/authentik/.env file with Authentik Host Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/authentik/.env file with Authentik Host Name...'
sleep 1

/bin/sed -i -e "s,AUTHENTIKHOST,${AUTHENTIK_HOST},g" "/opt/authentik/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/authentik/.env file with Authentik Domain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/authentik/.env file with Authentic Domain ...'
sleep 1

/bin/sed -i -e "s/AUTHENTIKDOMAIN/${AUTHENTIK_DOMAIN}/g" "/opt/authentik/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/authentik/.env file with Authentik Database" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/authentik/.env file with Authentic Database ...'
sleep 1

/bin/sed -i -e "s/POSTGRESDB/${POSTGRES_DB}/g" "/opt/authentik/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/authentik/.env file with Authentik Database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/authentik/.env file with Authentic Database Username ...'
sleep 1

/bin/sed -i -e "s/POSTGRESUSER/${POSTGRES_USER}/g" "/opt/authentik/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/authentik/.env file with Authentik Secret Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/authentik/.env file with Authentic Secret Key ...'
sleep 1

/bin/sed -i -e "s/AUTHENTIKSECRETKEY/${AUTHENTIK_SECRET_KEY}/g" "/opt/authentik/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/authentik/.env file with Authentik Database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/authentik/.env file with Authentic Database Username ...'
sleep 1

/bin/sed -i -e "s/POSTGRESPASSWORD/${POSTGRES_PASSWORD}/g" "/opt/authentik/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/authentik/.env file with GeoIP Account ID" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/authentik/.env file with GeoIP Account ID ...'
sleep 1

/bin/sed -i -e "s/GEOIPUPDATEACCOUNTID/${GEOIPUPDATE_ACCOUNT_ID}/g" "/opt/authentik/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/authentik/.env file with GeoIP License Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/authentik/.env file with GeoIP License Key ...'
sleep 1

/bin/sed -i -e "s/GEOIPUPDATELICENSEKEY/${GEOIPUPDATE_LICENSE_KEY}/g" "/opt/authentik/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/authentik/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/authentik/docker-compose.yml file with network name of Traefik container...'
sleep 1

/bin/sed -i -e "s,TRAEFIKNETWORK,${TRAEFIK_NETWORK},g" "/opt/authentik/docker-compose.yml" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/authentik/docker-compose-override.yml file with Authentik Data Path" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Configuring /opt/authentik/docker-compose.yml file with Authentik Data Path ...'
sleep 1

/bin/sed -i -e "s,AUTHENTIDATAPATH,${AUTHENTIK_DATA_PATH},g" "/opt/authentik/docker-compose-overrride.yml" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Starting Authentik Docker Stack" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Starting Authentik Docker Stack...'
sleep 1

cd /opt/authentik && /usr/local/bin/docker-compose up -d >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "FINISHED INSTALLATION. ENSURE ZABBIX DOCKER STACK IS UP AND RUNNING" | boxes -d stone -p a2v1
echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE AUTHENTIK DOCKER STACK IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
echo "Access Authentik by navigating with your web browser to https://$AUTHENTIK_HOST.$AUTHENTIK_DOMAIN/if/flow/initial-setup/ and and setup the Email and Password for the the default akadmin account"  | boxes -d stone -p a2v1
















