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

#Check if /opt/guacamole exists and if not create it
if [ ! -d "/opt/guacamole" ]; then
      /bin/mkdir -p /opt/guacamole
      echo "/opt/guacamole directory does not exist. Creating...."
   fi

#Check if /opt/guacamole exists and if not exit
if [ ! -d "/opt/guacamole" ]; then
      echo "${RED}The /opt/guacamole directory does not exist even after attempting to create automatically. Exiting for now... ${RESET}"
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
/bin/mkdir -p /opt/guacamole/dbdata

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
echo "Guacamole Installation" | boxes -d stone -p a2v1

PS3='Do you wish to continue the installation of Guacamole?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "[`date +%m/%d/%Y-%H:%M`] Starting Guacamole Installation." >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1

            echo "Starting Guacamole Installation. View progress at $SCRIPTPATH/install_log-$TIMESTAMP.log" | boxes -d stone -p a2v1

          break
            ;;
        "No")

            echo "Exiting Guacamole installation";
            exit
            ;;

        *) echo "invalid option $REPLY";;
    esac
done


read -p "Enter the Guacamole Postgres SQL username you wish to use:"  POSTGRES_USERNAME

if [ -z "$POSTGRES_USERNAME" ]
then
      echo "${RED}Postgres SQL username cannot be empty ${RESET}"
      exit
fi

read -p "Enter the Guacamole Postgres SQL password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your password):"  POSTGRES_PASSWORD

if [ -z "$POSTGRES_PASSWORD" ]
then

      echo "${RED}Postgres SQL password cannot be empty ${RESET}"
      exit
fi


read -p "Enter the Guacamole hostname you wish to use (Example: guacamole):"  ACME_HOSTNAME

if [ -z "$ACME_HOSTNAME" ]
then
      echo "${RED}Guacamole hostname cannot be empty ${RESET}"
      exit
fi

#Export the variable
export ACME_HOSTNAME

read -p "Enter the Guacamole subdomain you wish to use (Example: domain.tld):"  ACME_DOMAIN

if [ -z "$ACME_DOMAIN" ]
then
   
      echo "${RED}Guacamole subdomain cannot be empty ${RESET}"
      exit
fi

#Export the variable
export ACME_DOMAIN

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

/bin/cp $SCRIPTPATH/README.md /opt/guacamole/README.md

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error creating README.md file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error creating README.md file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Creating /opt/guacamole/dbinit/initdb.sql"
echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/guacamole/dbinit/initdb.sql" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/mkdir -p /opt/guacamole/dbinit
/usr/bin/docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --postgres > /opt/guacamole/dbinit/initdb.sql

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error creating /opt/guacamole/dbinit/initdb.sql ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error creating /opt/guacamole/dbinit/initdb.sql" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi


#echo "Creating /opt/guacamole/dbinit"
#echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/guacamole/dbinit" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

#/bin/cp -r $SCRIPTPATH/dbinit/ /opt/guacamole/

#if [ $? -eq 0 ]; then
    #echo "${GREEN}Done ${RESET}"
#else
        #echo "${RED}Error creating /opt/guacamole/dbinit ${RESET}"
        #echo "[`date +%m/%d/%Y-%H:%M`] Error creating /opt/guacamole/dbinit" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        #exit
#fi


echo "Creating /opt/guacamole/guacamole_home"
echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/guacamole/guacamole_home" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp -r $SCRIPTPATH/guacamole_home/ /opt/guacamole/

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating /opt/guacamole/guacamole_home ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating /opt/guacamole/guacamole_home" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi


echo "Creating docker-compose.yml file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp $SCRIPTPATH/templates/guacamole-docker-compose-template.yml /opt/guacamole/docker-compose.yml

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating docker-compose.yml file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Creating /opt/guacamole/.env file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/guacamole/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

#create /opt/guacamole/.env
/bin/cp -r $SCRIPTPATH/templates/.env-template /opt/guacamole/.env

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating /opt/guacamole/.env file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating /opt/guacamole/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/guacamole/.env file with Guacamole PostgreSQL Username"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/guacamole/.env file with Guacamole PostgreSQL Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,POSTGRESUSER,${POSTGRES_USERNAME},g" "/opt/guacamole/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/guacamole/.env file with Guacamole PostgreSQL Username ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/guacamole/.env file with Guacamole PostgreSQL Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/guacamole/.env file with Guacamole PostgreSQL Password"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/guacamole/.env file with Guacamole PostgreSQL Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,POSTGRESPASSWORD,${POSTGRES_PASSWORD},g" "/opt/guacamole/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/guacamole/.env file with Guacamole PostgreSQL Password ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/guacamole/.env file with Guacamole PostgreSQL Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/guacamole/.env file with Guacamole Host Name"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/guacamole/.env file with Guacamole Host Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,ACMEHOSTNAME,${ACME_HOSTNAME},g" "/opt/guacamole/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/guacamole/.env file with Guacamole Host Name ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/guacamole/.env file with Guacamole Host Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/guacamole/.env file with Guacamole Subdomain"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/guacamole/.env file with Guacamole Subdomain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s/ACMEDOMAIN/${ACME_DOMAIN}/g" "/opt/guacamole/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/guacamole/.env file with Guacamole Subdomain ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/guacamole/.env file with Guacamole Subdomain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/guacamole/docker-compose.yml file with network name of Traefik container"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/guacamole/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,TRAEFIKNETWORK,${TRAEFIK_NETWORK},g" "/opt/guacamole/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/guacamole/docker-compose.yml file with network name of Traefik container ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/guacamole/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi


while true
do
PS3='Do you wish to enable Duo MFA Support: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            /bin/bash $SCRIPTPATH/ubuntu_1804_enable_duo_guacamole.sh
            exit
            ;;
        "No")
 
            echo "NOT installing Duo MFA Support"
            echo "[`date +%m/%d/%Y-%H:%M`] NOT installing Duo MFA Support" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
            echo "Starting Guacamole Docker Container"
            echo "[`date +%m/%d/%Y-%H:%M`] Starting Guacamole Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

            cd /opt/guacamole && /usr/local/bin/docker-compose up && /usr/local/bin/docker-compose down && /bin/cp $SCRIPTPATH/dbfix/pg_hba.conf /opt/guacamole/dbdata && /usr/local/bin/docker-compose up -d

            if [ $? -eq 0 ]; then
            echo "${GREEN}Done ${RESET}"
            else
            echo "${RED}Error Starting Guacamole Docker Container ${RESET}"
            echo "[`date +%m/%d/%Y-%H:%M`] Error Starting Guacamole Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
            exit
            fi

            echo "FINISHED INSTALLATION. ENSURE GUACAMOLE DOCKER CONTAINER IS UP AND RUNNING" | boxes -d stone -p a2v1
            echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE GUACAMOLE DOCKER CONTAINER IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
            echo "Access Guacamole by navigating with your web browser to https://$ACME_HOSTNAME.$ACME_DOMAIN"  | boxes -d stone -p a2v1

            exit
            ;;
        
        *) echo "invalid option $REPLY";;
    esac
done
done










