#!/bin/bash

#Set Font Colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`

PUID=1001
GUID=1001

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


#Set the script path
SCRIPTPATH=$(pwd)

#Set install_log Date/Time Stamp
TIMESTAMP=`date +%m-%d-%Y-%H%M`

#Export the variable
export TIMESTAMP

#GET INPUTS
echo "Wordpress Installation" | boxes -d stone -p a2v1

PS3='Do you wish to continue the installation of Wordpress?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "[`date +%m/%d/%Y-%H:%M`] Starting  Installation." >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1  | boxes -d stone -p a2v1

            echo "Starting Wordpress Installation. View progress at $SCRIPTPATH/install_log-$TIMESTAMP.log" | boxes -d stone -p a2v1

          break
            ;;
        "No")

            echo "Exiting Wordpress installation";
            exit
            ;;

        *) echo "invalid option $REPLY";;
    esac
done



read -p "Enter the Wordpress Site Name you wish to use with no spaces or special characters (Example: mysite):"  SITE_NAME

if [ -z "$SITE_NAME" ]
then
      echo "${RED}Wordpress Site Name cannot be empty ${RESET}"
      exit
fi

#Export the variable
export SITE_NAME

#read -p "Enter the Wordpress MySQL/MariaDB Root password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your password):"  MYSQL_ROOT_PASSWORD

#if [ -z "$MYSQL_ROOT_PASSWORD" ]
#then

#      echo "${RED}Wordpress MySQL/MariaDB Root password cannot be empty ${RESET}"
#      exit
#fi

#read -p "Enter the Wordpress MySQL/MariaDB Database Username you wish to use with no spaces or special characters (Example: wordpress):"  MYSQL_USERNAME

#if [ -z "$MYSQL_USERNAME" ]
#then

#      echo "${RED}Wordpress MySQL/MariaDB Database Username cannot be empty ${RESET}"
#      exit
#fi

#read -p "Enter the Wordpress MySQL/MariaDB Database Password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your Username):"  MYSQL_PASSWORD

#if [ -z "$MYSQL_PASSWORD" ]
#then

#      echo "${RED}Wordpress MySQL/MariaDB Database Password cannot be empty ${RESET}"
#      exit
#fi

read -p "Enter the Wordpress MySQL/MariaDB Database Name you wish to use with no spaces or special characters (Example: wordpress_db):"  MYSQL_DATABASE

if [ -z "$MYSQL_DATABASE" ]
then

      echo "${RED}Wordpress MySQL/MariaDB Database Name cannot be empty ${RESET}"
      exit
fi


read -p "Enter a PRIMARY ROOT domain for Wordpress INCLUDING www. in front if applicable (Example: www.domain.tld OR host.domain.tld):"  WORDPRESS_DOMAIN

if [ -z "$WORDPRESS_DOMAIN" ]
then
      echo "${RED}PRIMARY ROOT domain for Wordpress cannot be empty ${RESET}"
      exit
fi

#Export the variable
export WORDPRESS_DOMAIN


read -p "Enter additional domain for Wordpress (Example: domain.tld) OR leave blank and press enter if none: "  WORDPRESS_SECDOMAIN

#Export the variable
export WORDPRESS_SECDOMAIN


#IF WORDPRESS_SECDOMAIN IS EMPTY THEN SET WORDPRESS_ALLDOMAIN TO $WORDPRESS_DOMAIN IF NOT SET WORDPRESS_ALLDOMAIN TO $WORDPRESS_DOMAIN AND $WORDPRESS_SECDOMAIN
if [ -z "$WORDPRESS_SECDOMAIN" ]
then
WORDPRESS_ALLDOMAIN=$WORDPRESS_DOMAIN
     
else
WORDPRESS_ALLDOMAIN="\`${WORDPRESS_DOMAIN}\`,\`${WORDPRESS_SECDOMAIN}\`"
    
fi

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


read -p "Enter the full path to an EXISTING directory where your Wordpress Data will reside without an ending slash / (Example: /mnt/data):"  WORDPRESS_DATA_PATH

if [ -z "$WORDPRESS_DATA_PATH" ]
then
   
      echo "${RED}Wordpress Data Path cannot be empty ${RESET}"
      exit
fi

#Export the variable
export WORDPRESS_DATA_PATH


#Check if /opt/Wordpress-$SITE_NAME exists and if not create it
if [ ! -d "/opt/Wordpress-$SITE_NAME" ]; then
      /bin/mkdir -p /opt/Wordpress-$SITE_NAME
      echo "/opt/Wordpress-$SITE_NAME directory does not exist. Creating...."
   fi

#Check if /opt/Wordpress-$SITE_NAME exists and if not exit
if [ ! -d "/opt/Wordpress-$SITE_NAME" ]; then
      echo "${RED}The /opt/Wordpress-$SITE_NAME directory does not exist even after attempting to create automatically. Exiting for now... ${RESET}"
      exit 1
   fi


 

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating Wordpress Data directories in $WORDPRESS_DATA_PATH/$SITE_NAME ${RESET}"
        exit 1
fi

source "$(pwd)/spinner.sh"

# test success
start_spinner 'sleeping for 2 secs...'
sleep 2
stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Creating Wordpress Data directories in $WORDPRESS_DATA_PATH/$SITE_NAME" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Creating Wordpress Data directories...'
sleep 1


#Create necessary directories and setting permissions
/bin/mkdir -p /opt/Wordpress-$SITE_NAME/ofelia_config && \
/bin/mkdir -p $WORDPRESS_DATA_PATH/$SITE_NAME && \
/bin/mkdir -p $WORDPRESS_DATA_PATH/$SITE_NAME/db && \
/bin/mkdir -p $WORDPRESS_DATA_PATH/$SITE_NAME/db_backups && \
/bin/mkdir -p $WORDPRESS_DATA_PATH/$SITE_NAME/db_backups/$SITE_NAME && \
/bin/mkdir -p $WORDPRESS_DATA_PATH/$SITE_NAME/wordpress && \
/bin/chown -R $PUID:$GUID $WORDPRESS_DATA_PATH/$SITE_NAME 2>> $SCRIPTPATH/install_log-$TIMESTAMP.log

stop_spinner $?



#create /opt/Wordpress-$SITE_NAME/.env
echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating docker-compose.yml...'
sleep 1


/bin/cp $SCRIPTPATH/templates/wordpress-docker-compose-template.yml /opt/Wordpress-$SITE_NAME/docker-compose.yml >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?



echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/Wordpress-$SITE_NAME/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating .env file...'
sleep 1


#create /opt/Wordpress-$SITE_NAME/.env
/bin/cp -r $SCRIPTPATH/templates/.env-template /opt/Wordpress-$SITE_NAME/.env >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?



echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/Wordpress-$SITE_NAME/.env file with Wordpress Domain(s)" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

#=== CONFIGURE /opt/Wordpress-$SITE_NAME/.env STARTS HERE ===

start_spinner 'Configuring .env file with Wordpress Domain(s)...'
sleep 1

/bin/sed -i -e "s,WORDPRESSDOMAIN,${WORDPRESS_DOMAIN},g" "/opt/Wordpress-$SITE_NAME/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1
/bin/sed -i -e "s/WORDPRESSALLDOMAIN/${WORDPRESS_ALLDOMAIN}/g" "/opt/Wordpress-$SITE_NAME/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Creating Random Wordpress MySQL/MariaDB root Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating Random Wordpress MySQL/MariaDB root Password...'
sleep 1

MYSQL_ROOT_PASSWORD=`/bin/cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-20} | head -n 1` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Random Wordpress MySQL/MariaDB root Password is: $MYSQL_ROOT_PASSWORD" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Random Wordpress MySQL/MariaDB root Password is:${GREEN} $MYSQL_ROOT_PASSWORD ${RESET}" | boxes -d stone -p a2v1


echo "[`date +%m/%d/%Y-%H:%M`] Creating Random Wordpress MySQL/MariaDB Database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating Random Wordpress MySQL/MariaDB Database Username...'
sleep 1

MYSQL_USERNAME=`/bin/cat /dev/urandom | tr -dc 'a-z0-9' | fold -w ${1:-10} | head -n 1` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Random Wordpress MySQL/MariaDB Database Username is: $MYSQL_USERNAME" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Random Wordpress MySQL/MariaDB Database Username is:${GREEN} $MYSQL_USERNAME ${RESET}" | boxes -d stone -p a2v1



echo "[`date +%m/%d/%Y-%H:%M`] Creating Random Wordpress MySQL/MariaDB Database Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating Wordpress MySQL/MariaDB Database Password...'
sleep 1

MYSQL_PASSWORD=`/bin/cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-20} | head -n 1` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Random Wordpress MySQL/MariaDB Database Password is: $MYSQL_PASSWORD" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Random Wordpress MySQL/MariaDB Database Password is:${GREEN} $MYSQL_PASSWORD ${RESET}" | boxes -d stone -p a2v1



echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/Wordpress-$SITE_NAME/.env file with MySQL/MariaDB root Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with MySQL/MariaDB root Password..'
sleep 1

/bin/sed -i -e "s,MYSQLROOTPASSWORD,${MYSQL_ROOT_PASSWORD},g" "/opt/Wordpress-$SITE_NAME/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/Wordpress-$SITE_NAME/.env file with MySQL/MariaDB Database Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with MySQL/MariaDB Database Name...'
sleep 1

/bin/sed -i -e "s,MYSQLDATABASE,${MYSQL_DATABASE},g" "/opt/Wordpress-$SITE_NAME/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/Wordpress-$SITE_NAME/.env file with MySQL/MariaDB Database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with MySQL/MariaDB Database Username...'
sleep 1

/bin/sed -i -e "s,MYSQLUSERNAME,${MYSQL_USERNAME},g" "/opt/Wordpress-$SITE_NAME/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?



echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/Wordpress-$SITE_NAME/.env file with MySQL/MariaDB Database Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with MySQL/MariaDB Database Password...'
sleep 1

/bin/sed -i -e "s,MYSQLPASSWORD,${MYSQL_PASSWORD},g" "/opt/Wordpress-$SITE_NAME/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/Wordpress-$SITE_NAME/.env file with PUID" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with PUID...'
sleep 1

/bin/sed -i -e "s,P_UID,${PUID},g" "/opt/Wordpress-$SITE_NAME/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/Wordpress-$SITE_NAME/.env file with GUID" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with GUID...'
sleep 1

/bin/sed -i -e "s,G_UID,${GUID},g" "/opt/Wordpress-$SITE_NAME/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CONFIGURE /opt/Wordpress-$SITE_NAME/.env ENDS HERE ===

#=== CONFIGURE /opt/Wordpress-$SITE_NAME/docker-compose.yml STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/Wordpress-$SITE_NAME/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring docker-compose.yml file with with network name of Traefik container...'
sleep 1

/bin/sed -i -e "s,TRAEFIKNETWORK,${TRAEFIK_NETWORK},g" "/opt/Wordpress-$SITE_NAME/docker-compose.yml" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/Wordpress-$SITE_NAME/docker-compose.yml file with Wordpress Site Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring docker-compose.yml file with Wordpress Site Name...'
sleep 1

/bin/sed -i -e "s,SITENAME,${SITE_NAME},g" "/opt/Wordpress-$SITE_NAME/docker-compose.yml" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/Wordpress-$SITE_NAME/docker-compose.yml file with Wordpress Data Path" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring docker-compose.yml file with Wordpress Data Path...'
sleep 1

/bin/sed -i -e "s,WORDPRESSDATAPATH,${WORDPRESS_DATA_PATH},g" "/opt/Wordpress-$SITE_NAME/docker-compose.yml" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CONFIGURE /opt/Wordpress-$SITE_NAME/docker-compose.yml ENDS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Starting Wordpress Docker Containers" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Starting Wordpress Docker Containers...'
sleep 1

cd /opt/Wordpress-$SITE_NAME && /usr/local/bin/docker-compose up -d >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "FINISHED INSTALLATION. ENSURE Wordpress DOCKER CONTAINER IS UP AND RUNNING" | boxes -d stone -p a2v1

echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE Wordpress DOCKER CONTAINER IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1
            
echo "Access Wordpress by navigating with your web browser to https://$WORDPRESS_DOMAIN"  | boxes -d stone -p a2v1











