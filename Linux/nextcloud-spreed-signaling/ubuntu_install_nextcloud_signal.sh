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

#Check if docker-compose exists and if not exit
if [ ! -f "/usr/local/bin/docker-compose" ]; then
      echo "${RED}Docker Compose does not seem to be installed. Please install Docker Compose and try again. Exiting for now... ${RESET}"
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
echo "${GREEN}Done ${RESET}"
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
echo "${GREEN}Done ${RESET}"
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
echo "${GREEN}Done ${RESET}"
fi

echo "Installing OpenSSL Prerequisite"
#Install openssl
apt-get install openssl -y  > /dev/null 2>&1

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "${RED}Error $THEERROR, occurred Installing OpenSSL Prerequisite ${RESET}"
exit 1
else
echo "${GREEN}Done ${RESET}"
fi


#Set the script path
SCRIPTPATH=$(pwd)

#Set install_log Date/Time Stamp
TIMESTAMP=`date +%m-%d-%Y-%H%M`

#Export the variable
export TIMESTAMP

#GET INPUTS
echo "Nextcloud-Signal Installation" | boxes -d stone -p a2v1

PS3='Do you wish to continue the installation of Nextcloud-Signal?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "[`date +%m/%d/%Y-%H:%M`] Starting Nextcloud-Signal Installation." >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1  | boxes -d stone -p a2v1

            echo "Starting Nextcloud-Signal Installation. View progress at $SCRIPTPATH/install_log-$TIMESTAMP.log" | boxes -d stone -p a2v1

          break
            ;;
        "No")

            echo "Exiting Nextcloud-Signal installation";
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

read -p "Enter the Nextcloud instance URL that will be connecting to this server. MUST include https:// (Example: https://cloud.domain.tld):"  NEXTCLOUD_SERVER

if [ -z "$NEXTCLOUD_SERVER" ]
then
   
      echo "${RED}Nextcloud instance URL cannot be empty ${RESET}"
      exit
fi

#Export the variable
export NEXTCLOUD_SERVER

#=== GET USER INPUTS ENDS HERE ===

source "$(pwd)/spinner.sh"

# test success
start_spinner 'sleeping for 2 secs...'
sleep 2
stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Git cloning nextcloud-spreed-signaling to /opt/nextcloud-spreed-signaling" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Git cloning nextcloud-spreed-signaling to /opt/nextcloud-spreed-signaling...'
sleep 1

cd /opt/ >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
git clone https://github.com/strukturag/nextcloud-spreed-signaling.git >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CREATING FILES STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/nextcloud-spreed-signaling/.gitignore file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating .gitignore file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/.gitignore
/bin/cp -r $SCRIPTPATH/templates/.gitignore-template /opt/nextcloud-spreed-signaling/.gitignore >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/nextcloud-spreed-signaling/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating .env file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/.env
/bin/cp -r $SCRIPTPATH/templates/.env-template /opt/nextcloud-spreed-signaling/.env >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/nextcloud-spreed-signaling/server.conf file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating server.conf file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/server.conf
/bin/cp -r $SCRIPTPATH/templates/server-template.conf /opt/nextcloud-spreed-signaling/server.conf >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating docker-compose.yml...'
sleep 1

/bin/cp $SCRIPTPATH/templates/nextcloud-signal-docker-compose-template.yml /opt/nextcloud-spreed-signaling/docker-compose.yml >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /etc/cron.d/certbot_renew file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating /etc/cron.d/certbot_renew file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/server.conf
/bin/cp -r $SCRIPTPATH/templates/certbot_renew /etc/cron.d/certbot_renew >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating Nginx default site file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/nginx/conf/nginx/default
/bin/cp -rf $SCRIPTPATH/nginx/ /opt/nextcloud-spreed-signaling/nginx/ >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating Certbot Certificate Directory Structure" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating Creating Certbot Certificate Directory Structure...'
sleep 1

#create /opt/nextcloud-spreed-signaling/certbot/conf/dummy directory
mkdir -p /opt/nextcloud-spreed-signaling/certbot >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/conf >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/conf/dummy >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/conf/dummy/$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Generating Self Signed Certificate for Nginx" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Generating Self Signed Certificate for Nginx...'
sleep 1

#generate self signed cert for Nginx
/usr/bin/openssl req -batch -x509 -newkey rsa:4096 -nodes -keyout /opt/nextcloud-spreed-signaling/certbot/conf/dummy/$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN/privkey.pem -out /opt/nextcloud-spreed-signaling/certbot/conf/dummy/$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN/fullchain.pem -sha256 -days 1825 >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CREATING FILES ENDS HERE ===

#=== GENERATING VARIABLES STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Generating Static Secret Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Static Secret Random String...'
sleep 1

STATIC_SECRET=`/usr/bin/openssl rand -hex 32` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Static Secret is: $STATIC_SECRET" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Static Secret is:${GREEN} $STATIC_SECRET ${RESET}" | boxes -d stone -p a2v1


echo "[`date +%m/%d/%Y-%H:%M`] Generating Hash Key Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Hash Key Random String...'
sleep 1

HASH_KEY=`/usr/bin/openssl rand -base64 16` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Generating Block Key Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Block Key Random String...'
sleep 1

BLOCK_KEY=`/usr/bin/openssl rand -base64 16` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Generating Nextcloud Shared Secret Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Nextcloud Shared Secret Random String...'
sleep 1

SHARED_SECRET=`/usr/bin/openssl rand -hex 32` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Shared Secret is: $SHARED_SECRET" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Shared Secret is:${GREEN} $SHARED_SECRET ${RESET}" | boxes -d stone -p a2v1

echo "[`date +%m/%d/%Y-%H:%M`] Generating Api Key Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Api Key Random String...'
sleep 1

API_KEY=`/usr/bin/openssl rand -hex 16` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== GENERATING VARIABLES ENDS HERE ===

#=== CONFIGURING FILES STARTS HERE ===

#=== CONFIGURE /opt/nextcloud-spreed-signaling/.env STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/.env file with Nextcloud-Signal Hostname" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with Nextcloud-Signal Hostname...'
sleep 1

/bin/sed -i -e "s,SIGNALHOSTNAME,${SIGNAL_HOSTNAME},g" "/opt/nextcloud-spreed-signaling/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/.env file with Nextcloud-Signal Domain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with Nextcloud-Signal Domain...'
sleep 1

/bin/sed -i -e "s,SIGNALDOMAIN,${SIGNAL_DOMAIN},g" "/opt/nextcloud-spreed-signaling/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/.env file with Static Secret" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with Static Secret...'
sleep 1

/bin/sed -i -e "s,STATICSECRET,${STATIC_SECRET},g" "/opt/nextcloud-spreed-signaling/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CONFIGURE /opt/nextcloud-spreed-signaling/.env ENDS HERE ===

#=== CONFIGURE /opt/nextcloud-spreed-signaling/server.conf STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Hash Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Hash Key...'
sleep 1

/bin/sed -i -e "s,HASHKEY,${HASH_KEY},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Block Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Block Key...'
sleep 1

/bin/sed -i -e "s,BLOCKKEY,${BLOCK_KEY},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Nextcloud instance URL" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Nextloud instance URL...'
sleep 1

/bin/sed -i -e "s,NEXTCLOUDSERVER,${NEXTCLOUD_SERVER},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Nextcloud Shared Secret" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Nextcloud Shared Secret...'
sleep 1

/bin/sed -i -e "s,SHAREDSECRET,${SHARED_SECRET},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Api Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Api Key...'
sleep 1

/bin/sed -i -e "s,APIKEY,${API_KEY},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CONFIGURE /opt/nextcloud-spreed-signaling/server.conf ENDS HERE ===

#=== CONFIGURE /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default file with Nextcloud-Signal Hostname" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring Nginx default file with Nextcloud-Signal Hostname...'
sleep 1

/bin/sed -i -e "s,SIGNALHOSTNAME,${SIGNAL_HOSTNAME},g" "/opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default file with Nextcloud-Signal Domain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring Nginx default file with Nextcloud-Signal Domain...'
sleep 1

/bin/sed -i -e "s,SIGNALDOMAIN,${SIGNAL_DOMAIN},g" "/opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CONFIGURE /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default ENDS HERE ===

#=== CONFIGURE /etc/cron.d/certbot_renew STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /etc/cron.d/certbot_renew file with Nextcloud-Signal Hostname" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring /etc/cron.d/certbot_renew file with Nextcloud-Signal Hostname...'
sleep 1

/bin/sed -i -e "s,SIGNALHOSTNAME,${SIGNAL_HOSTNAME},g" "/etc/cron.d/certbot_renew" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /etc/cron.d/certbot_renew file with Nextcloud-Signal Domain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring /etc/cron.d/certbot_renew file with Nextcloud-Signal Domain...'
sleep 1

/bin/sed -i -e "s,SIGNALDOMAIN,${SIGNAL_DOMAIN},g" "/etc/cron.d/certbot_renew" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


#=== CONFIGURE /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default ENDS HERE ===


echo "[`date +%m/%d/%Y-%H:%M`] Building Nextcloud-Signal Docker Containers" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Building Nextcloud-Signal Docker Containers...'
sleep 1

cd /opt/nextcloud-spreed-signaling && docker-compose build >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Starting Nextcloud-Signal Docker Containers" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Starting Nextcloud-Signal Docker Containers...'
sleep 1

cd /opt/nextcloud-spreed-signaling && /usr/local/bin/docker network create "spreed" && docker-compose up -d >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "FINISHED INSTALLATION. ENSURE ALL CONTAINERS ARE UP AND RUNNING" | boxes -d stone -p a2v1

echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE ALL CONTAINERS ARE UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1
            
#echo "Access Nextcloud-Signal by navigating with your web browser to https://$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN"  | boxes -d stone -p a2v1


