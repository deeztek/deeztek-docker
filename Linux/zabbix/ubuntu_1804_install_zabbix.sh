#!/bin/bash

#Set Font Colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`

#The script below assumes you have a fully installed and updated Ubuntu 18.04 server and you have installed docker and docker-compose and traefik

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

echo "Installing pre-requisite package boxes"
#Install boxes
/usr/bin/apt install boxes -y

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Installing pre-requisite package boxes${RESET}"
        exit 1
fi

echo "Git cloning zabbix-docker from https://github.com/zabbix/zabbix-docker to /opt/zabbix-docker"
#git clone zabbix-docker
/usr/bin/git clone https://github.com/zabbix/zabbix-docker.git /opt/zabbix-docker

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error git cloning zabbix-docker from https://github.com/zabbix/zabbix-docker to /opt/zabbix-docker ${RESET}"
        exit 1
fi

#Check if /opt/zabbix-docker exists and if not exit
echo "Checking if /opt/zabbix-docker directory exists"
if [ ! -d "/opt/zabbix-docker" ]; then
echo "${RED}The /opt/zabbix-docker directory does not exist. Exiting for now... ${RESET}"
exit 1
else
echo "${GREEN}Exists ${RESET}"
fi

echo "Creating pre-requisite directories"
#Create necessary directories and files
/bin/mkdir -p /opt/zabbix-docker/ofelia_config && \
/bin/mkdir -p /opt/zabbix-docker/ofelia_logs


if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Creating pre-requisite directories ${RESET}"
        exit 1
fi


#Set the script path
SCRIPTPATH=$(pwd)

#Set install_log Date/Time Stamp
TIMESTAMP=`date +%m-%d-%Y-%H%M`

#Export the variable
export TIMESTAMP

#GET INPUTS
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


read -p "Enter the Zabbix MySQL database username you wish to use (Example: zabbix):"  MYSQL_USERNAME

if [ -z "$MYSQL_USERNAME" ]
then
      echo "${RED}Zabbix MySQL database username cannot be empty ${RESET}"
      exit
fi

read -p "Enter the Zabbix MySQL database password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your password):"  MYSQL_PASSWORD

if [ -z "$MYSQL_PASSWORD" ]
then

      echo "${RED}Zabbix MySQL database password cannot be empty ${RESET}"
      exit
fi


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


read -p "Enter the network name of your Traefik container from the listing above (Example: proxy)"  TRAEFIK_NETWORK

if [ -z "$TRAEFIK_NETWORK" ]
then
   
      echo "${RED}the network name of your Traefik container cannot be empty ${RESET}"
      exit
fi



echo "Creating README.md file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating README.md file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp $SCRIPTPATH/README.md /opt/zabbix-docker/README.md

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error creating README.md file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error creating README.md file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Creating /opt/zabbix-docker/ofelia_config/config.ini"
echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/zabbix-docker/ofelia_config/config.ini" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp -r $SCRIPTPATH/ofelia_config/config.ini /opt/zabbix-docker/ofelia_config/config.ini

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error creating /opt/zabbix-docker/ofelia_config/config.ini ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error creating /opt/zabbix-docker/ofelia_config/config.ini" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi


echo "Creating docker-compose.yml file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp $SCRIPTPATH/templates/zabbix-docker-compose-template.yml /opt/zabbix-docker/docker-compose.yml

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating docker-compose.yml file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Creating /opt/zabbix-docker/.env file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/zabbix-docker/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

#create /opt/Zabbix/.env
/bin/cp -r $SCRIPTPATH/templates/.env-template /opt/zabbix-docker/.env

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating /opt/zabbix-docker/.env file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating /opt/zabbix-docker/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/zabbix-docker/.env file with Zabbix Host Name"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/.env file with Zabbix Host Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,ACMEHOSTNAME,${ACME_HOSTNAME},g" "/opt/zabbix-docker/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/zabbix-docker/.env file with Zabbix Host Name ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/zabbix-docker/.env file with Zabbix Host Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/zabbix-docker/.env file with Zabbix Subdomain"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/.env file with Zabbix Subdomain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s/ACMEDOMAIN/${ACME_DOMAIN}/g" "/opt/zabbix-docker/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/zabbix-docker/.env file with Zabbix Subdomain ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/zabbix-docker/.env file with Zabbix Subdomain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/zabbix-docker/.MYSQL_ROOT_PASSWORD file with Zabbix MySQL root password"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/.MYSQL_ROOT_PASSWORD file with Zabbix MySQL root password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

touch /opt/zabbix-docker/.MYSQL_ROOT_PASSWORD
/bin/sed -i -e "s,root_pwd,${MYSQL_ROOT},g" "/opt/zabbix-docker/.MYSQL_ROOT_PASSWORD"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring opt/zabbix-docker/.MYSQL_ROOT_PASSWORD file with Zabbix MySQL root password ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring opt/zabbix-docker/.MYSQL_ROOT_PASSWORD file with Zabbix MySQL root password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/zabbix-docker/.MYSQL_USER file with Zabbix MySQL database username"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/.MYSQL_USER file with Zabbix MySQL database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

touch /opt/zabbix-docker/.MYSQL_USER
/bin/sed -i -e "s,zabbix,${MYSQL_USERNAME},g" "/opt/zabbix-docker/.MYSQL_USER"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/zabbix-docker/.MYSQL_USER file with Zabbix MySQL database Username ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/zabbix-docker/.MYSQL_USER file with Zabbix MySQL database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/zabbix-docker/.MYSQL_PASSWORD file with Zabbix MySQL database password"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/.MYSQL_PASSWORD file with Zabbix MySQL database password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

touch /opt/zabbix-docker/.MYSQL_PASSWORD
/bin/sed -i -e "s,zabbix,${MYSQL_PASSWORD},g" "/opt/zabbix-docker/.MYSQL_PASSWORD"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/zabbix-docker/.MYSQL_USER file with Zabbix MySQL database password ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/zabbix-docker/.MYSQL_USER file with Zabbix MySQL database password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi



echo "Configuring /opt/zabbix-docker/docker-compose.yml file with network name of Traefik container"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,TRAEFIKNETWORK,${TRAEFIK_NETWORK},g" "/opt/zabbix-docker/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/zabbix-docker/docker-compose.yml file with network name of Traefik container ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/zabbix-docker/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi


echo "Starting Zabbix Docker Container"
echo "[`date +%m/%d/%Y-%H:%M`] Starting Zabbix Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

cd /opt/zabbix-docker && /usr/local/bin/docker-compose up -d

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
echo "${RED}Error Starting Zabbix Docker Container ${RESET}"
echo "[`date +%m/%d/%Y-%H:%M`] Error Starting Zabbix Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
exit
fi

echo "FINISHED INSTALLATION. ENSURE ZABBIX DOCKER CONTAINER IS UP AND RUNNING" | boxes -d stone -p a2v1
echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE ZABBIX DOCKER CONTAINER IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
echo "Access Zabbix by navigating with your web browser to https://$ACME_HOSTNAME.$ACME_DOMAIN and login with default credentials of Admin/zabbix"  | boxes -d stone -p a2v1











