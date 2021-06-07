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

echo "Installing pre-requisite package boxes and apache2-utils"
#Install boxes and apche2-utils
/usr/bin/apt install boxes -y && \
/usr/bin/apt install apache2-utils -y

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Installing pre-requisite package boxes and apache2-utils ${RESET}"
        exit 1
fi



#Set the script path
SCRIPTPATH=$(pwd)

#Set install_log Date/Time Stamp
TIMESTAMP=`date +%m-%d-%Y-%H%M`

#Export the variable
export TIMESTAMP

#GET INPUTS
echo "OnlyOffice Installation" | boxes -d stone -p a2v1

PS3='Do you wish to continue the installation of OnlyOffice?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "[`date +%m/%d/%Y-%H:%M`] Starting OnlyOffice Installation." >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1

            echo "Starting OnlyOffice Installation. View progress at $SCRIPTPATH/install_log-$TIMESTAMP.log" | boxes -d stone -p a2v1

          break
            ;;
        "No")

            echo "Exiting OnlyOffice installation";
            exit
            ;;

        *) echo "invalid option $REPLY";;
    esac
done



read -p "Enter the OnlyOffice Site Name you wish to use with no spaces or special characters (Example: mysite):"  SITE_NAME

if [ -z "$SITE_NAME" ]
then
      echo "${RED}OnlyOffice Site Name cannot be empty ${RESET}"
      exit
fi

#Export the variable
export SITE_NAME


read -p "Enter the OnlyOffice Database Username you wish to use with no spaces or special characters (Example: onlyoffice):"  DB_USERNAME

if [ -z "$DB_USERNAME" ]
then

      echo "${RED}OnlyOffice Database Username cannot be empty ${RESET}"
      exit
fi

read -p "Enter the OnlyOffice Database Password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your Username):"  DB_PASSWORD

if [ -z "$DB_PASSWORD" ]
then

      echo "${RED}OnlyOffice Database Password cannot be empty ${RESET}"
      exit
fi

read -p "Enter the OnlyOffice Database Name you wish to use with no spaces or special characters (Example: onlyoffice_db):"  DB_NAME

if [ -z "$DB_NAME" ]
then

      echo "${RED}OnlyOffice Database Name cannot be empty ${RESET}"
      exit
fi

read -p "Enter the OnlyOffice JSON Web Token (JWT) you wish to use with at least 20 characters with no spaces (Example: ncadmin):"  ONLYOFFICE_JWT

if [ -z "$ONLYOFFICE_JWT" ]
then

      echo "${RED}OnlyOffice OnlyOffice JSON Web Token (JWT) cannot be empty ${RESET}"
      exit
fi


read -p "Enter the OnlyOffice Hostname you wish to use (Example: office):"  ONLYOFFICE_HOSTNAME

if [ -z "$ONLYOFFICE_HOSTNAME" ]
then
      echo "${RED}OnlyOffice Hostname cannot be empty ${RESET}"
      exit
fi

#Export the variable
export ONLYOFFICE_HOSTNAME

read -p "Enter the OnlyOffice Subdomain you wish to use (Example: domain.tld):"  ONLYOFFICE_DOMAIN

if [ -z "$ONLYOFFICE_DOMAIN" ]
then
   
      echo "${RED}OnlyOffice Subdomain cannot be empty ${RESET}"
      exit
fi

#Export the variable
export ONLYOFFICE_DOMAIN

#Output containers and their networks
echo "${GREEN}Below is a listing of your containers and their associated networks.
Locate the Traefik container network name and enter it in the prompt below.
If you are not able to locate the Traefik container, ensure Traefik is configured
and running ${RESET}"

/usr/bin/docker container ls --format 'table {{.Names}}\t{{.Networks}}'  | boxes -d stone -p a2v1


read -p "Enter the network name of your Traefik container from the listing above (Example: proxy)"  TRAEFIK_NETWORK

if [ -z "$TRAEFIK_NETWORK" ]
then
   
      echo "${RED}the network name of your Traefik container cannot be empty ${RESET}"
      exit
fi


#Check if /opt/$SITE_NAME-OnlyOffice exists and if not create it
if [ ! -d "/opt/$SITE_NAME-OnlyOffice" ]; then
      /bin/mkdir -p /opt/$SITE_NAME-OnlyOffice
      echo "/opt/$SITE_NAME-OnlyOffice directory does not exist. Creating...."
   fi

#Check if /opt/$SITE_NAME-OnlyOffice exists and if not exit
if [ ! -d "/opt/$SITE_NAME-OnlyOffice" ]; then
      echo "${RED}The /opt/$SITE_NAME-OnlyOffice directory does not exist even after attempting to create automatically. Exiting for now... ${RESET}"
      exit 1
   fi


echo "Creating docker-compose.yml"
echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp $SCRIPTPATH/templates/onlyoffice-docker-compose-template.yml /opt/$SITE_NAME-OnlyOffice/docker-compose.yml

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating docker-compose.yml file${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi



echo "Creating /opt/$SITE_NAME-OnlyOffice/.env file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/$SITE_NAME-OnlyOffice/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

#create /opt/$SITE_NAME-OnlyOffice/.env
/bin/cp -r $SCRIPTPATH/templates/.env-template /opt/$SITE_NAME-OnlyOffice/.env

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating /opt/$SITE_NAME-OnlyOffice/.env file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating /opt/$SITE_NAME-OnlyOffice/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi


echo "Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Hostname"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Hostname" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,ONLYOFFICEHOSTNAME,${ONLYOFFICE_HOSTNAME},g" "/opt/$SITE_NAME-OnlyOffice/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Hostname ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Host Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Subdomain"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Subdomain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,ONLYOFFICEDOMAIN,${ONLYOFFICE_DOMAIN},g" "/opt/$SITE_NAME-OnlyOffice/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Subdomain ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Subdomain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Name"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,DBNAME,${DB_NAME},g" "/opt/$SITE_NAME-OnlyOffice/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Name ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Username"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,DBUSERNAME,${DB_USERNAME},g" "/opt/$SITE_NAME-OnlyOffice/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Username ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Password"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,DBPASSWORD,${DB_PASSWORD},g" "/opt/$SITE_NAME-OnlyOffice/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Password ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice Database Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice JWT Secret"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice JWT Secret" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,JWTSECRET,${ONLYOFFICE_JWT},g" "/opt/$SITE_NAME-OnlyOffice/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice JWT Secret ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-OnlyOffice/.env file with OnlyOffice JWT Secret" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

#=== CONFIGURE /opt/$SITE_NAME-OnlyOffice/.env ENDS HERE ===

#=== CONFIGURE /opt/$SITE_NAME-OnlyOffice/docker-compose.yml ENDS HERE ===


echo "Configuring /opt/$SITE_NAME-OnlyOffice/docker-compose.yml file with network name of Traefik container"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-OnlyOffice/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,TRAEFIKNETWORK,${TRAEFIK_NETWORK},g" "/opt/$SITE_NAME-OnlyOffice/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-OnlyOffice/docker-compose.yml file with network name of Traefik container ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-OnlyOffice/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-OnlyOffice/docker-compose.yml file with OnlyOffice Site Name"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-OnlyOffice/docker-compose.yml file with OnlyOffice Site Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,SITENAME,${SITE_NAME},g" "/opt/$SITE_NAME-OnlyOffice/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-OnlyOffice/docker-compose.yml file with Nextcloud Site Name ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-OnlyOffice/docker-compose.yml file with Nextcloud Site Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

#=== CONFIGURE /opt/$SITE_NAME-OnlyOffice/docker-compose.yml ENDS HERE ===

echo "Starting OnlyOffice Docker Container"
echo "[`date +%m/%d/%Y-%H:%M`] Starting OnlyOffice Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

cd /opt/$SITE_NAME-OnlyOffice && /usr/local/bin/docker-compose up -d

            if [ $? -eq 0 ]; then
            echo "${GREEN}Done ${RESET}"
            else
            echo "${RED}Error Starting OnlyOffice Docker Container ${RESET}"
            echo "[`date +%m/%d/%Y-%H:%M`] Error Starting OnlyOffice Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
            exit
            fi

            echo "FINISHED INSTALLATION. ENSURE ONLYFFICE DOCKER CONTAINER IS UP AND RUNNING" | boxes -d stone -p a2v1
            echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE OnlyOffice DOCKER CONTAINER IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
            echo "Access OnlyOffice by navigating with your web browser to https://$ONLYOFFICE_HOSTNAME.$ONLYOFFICE_DOMAIN"  | boxes -d stone -p a2v1











