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

#Check if /opt/portainer exists and if not create it
if [ ! -d "/opt/portainer" ]; then
      /bin/mkdir -p /opt/portainer
      echo "/opt/portainer directory does not exist. Creating...."
   fi

#Check if /opt/portainer exists and if not exit
if [ ! -d "/opt/portainer" ]; then
      echo "${RED}The /opt/portainer directory does not exist even after attempting to create automatically. Exiting for now... ${RESET}"
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

echo "Creating pre-requisite directories files and setting permissions"
#Create necessary directories and files
/bin/mkdir -p /opt/portainer/certs
/bin/mkdir -p /opt/portainer/portainer_data

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Creating pre-requisite directories files and setting permissions ${RESET}"
        exit 1
fi


#Set the script path
SCRIPTPATH=$(pwd)

#Set install_log Date/Time Stamp
TIMESTAMP=`date +%m-%d-%Y-%H%M`

#Export the variable
export TIMESTAMP

#GET INPUTS
echo "Portainer Installation" | boxes -d stone -p a2v1

PS3='Do you wish to continue the installation of Portainer?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "[`date +%m/%d/%Y-%H:%M`] Starting Portainer Installation." >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1

            echo "Starting Portainer Installation. View progress at $SCRIPTPATH/install_log-$TIMESTAMP.log" | boxes -d stone -p a2v1

          break
            ;;
        "No")

            echo "Exiting Portainer installation";
            exit
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

echo "Creating README.md file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating README.md file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp $SCRIPTPATH/README.md /opt/portainer/README.md

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error creating README.md file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error creating README.md file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi



echo "Creating docker-compose.yml file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp $SCRIPTPATH/templates/portainer-docker-compose-template.yml /opt/portainer/docker-compose.yml

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating docker-compose.yml file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi


echo "Creating Portainer SSL Certificate and Key"
echo "[`date +%m/%d/%Y-%H:%M`] Creating Portainer SSL Certificate and Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/usr/bin/openssl genrsa -out /opt/portainer/certs/portainer.key 4096 && \
/usr/bin/openssl ecparam -genkey -name secp384r1 -out /opt/portainer/certs/portainer.key && \
/usr/bin/openssl req -new -x509 -sha256 -key /opt/portainer/certs/portainer.key -out /opt/portainer/certs/portainer.crt -days 3650

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating Portainer SSL Certificate and Key ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating Portainer SSL Certificate and Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Starting Portainer Docker Container"
echo "[`date +%m/%d/%Y-%H:%M`] Starting Portainer Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

cd /opt/portainer && /usr/local/bin/docker-compose up -d

if [ $? -eq 0 ]; then
        echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Starting Portainer Docker Container ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Starting Portainer Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "FINISHED INSTALLATION. ENSURE PORTAINER DOCKER CONTAINER IS UP AND RUNNING" | boxes -d stone -p a2v1
echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE PORTAINER DOCKER CONTAINER IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
echo "Access Portainer by navigating with your web browser to https://IP_ADDRESS:9000"  | boxes -d stone -p a2v1












