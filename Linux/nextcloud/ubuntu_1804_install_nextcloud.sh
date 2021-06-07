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
echo "Nextcloud Installation" | boxes -d stone -p a2v1

PS3='Do you wish to continue the installation of Nextcloud?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "[`date +%m/%d/%Y-%H:%M`] Starting Nextcloud Installation." >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1

            echo "Starting Nextcloud Installation. View progress at $SCRIPTPATH/install_log-$TIMESTAMP.log" | boxes -d stone -p a2v1

          break
            ;;
        "No")

            echo "Exiting Nextcloud installation";
            exit
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

PS3='Do you wish to enable SMB/CIFS Support in Nextcloud?'
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "[`date +%m/%d/%Y-%H:%M`] Enabling Nextcloud SMB/CIFS Support" >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1
            echo "Enabling Nextcloud SMB/CIFS" | boxes -d stone -p a2v1
            SMB_SUPPORT=$opt

          break
            ;;
        "No")
            echo "[`date +%m/%d/%Y-%H:%M`] NOT Enabling Nextcloud SMB/CIFS Support" >> $SCRIPTPATH/install_log-$TIMESTAMP.log  | boxes -d stone -p a2v1
            echo "NOT Enabling Nextcloud SMB/CIFS Support";
            SMB_SUPPORT=$opt
          break
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

#Export the variable
export SMB_SUPPORT

read -p "Enter the Nextcloud Site Name you wish to use with no spaces or special characters (Example: mysite):"  SITE_NAME

if [ -z "$SITE_NAME" ]
then
      echo "${RED}Nextcloud Site Name cannot be empty ${RESET}"
      exit
fi

#Export the variable
export SITE_NAME

read -p "Enter the Nextcloud MySQL/MariaDB Root password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your password):"  MYSQL_ROOT_PASSWORD

if [ -z "$MYSQL_ROOT_PASSWORD" ]
then

      echo "${RED}MySQL/MariaDB Root password cannot be empty ${RESET}"
      exit
fi

read -p "Enter the Nextcloud MySQL/MariaDB Nextcloud Database Username you wish to use with no spaces or special characters (Example: nextcloud):"  MYSQL_USERNAME

if [ -z "$MYSQL_USERNAME" ]
then

      echo "${RED}Nextcloud MySQL/MariaDB Nextcloud Database Username cannot be empty ${RESET}"
      exit
fi

read -p "Enter the Nextcloud MySQL/MariaDB Nextcloud Database Password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your Username):"  MYSQL_PASSWORD

if [ -z "$MYSQL_PASSWORD" ]
then

      echo "${RED}Nextcloud MySQL/MariaDB Nextcloud Database Password cannot be empty ${RESET}"
      exit
fi

read -p "Enter the Nextcloud MySQL/MariaDB Nextcloud Database Name you wish to use with no spaces or special characters (Example: nextcloud_db):"  MYSQL_DATABASE

if [ -z "$MYSQL_DATABASE" ]
then

      echo "${RED}Nextcloud MySQL/MariaDB Nextcloud Database Name cannot be empty ${RESET}"
      exit
fi

read -p "Enter the Nextcloud Admin Username you wish to use with no spaces or special characters (Example: ncadmin):"  NEXTCLOUD_USERNAME

if [ -z "$NEXTCLOUD_USERNAME" ]
then

      echo "${RED}Nextcloud Admin Username cannot be empty ${RESET}"
      exit
fi

read -p "Enter the Nextcloud Admin Password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your password):"  NEXTCLOUD_PASSWORD

if [ -z "$NEXTCLOUD_PASSWORD" ]
then

      echo "${RED}Nextcloud Admin Password cannot be empty ${RESET}"
      exit
fi

read -p "Enter the Nextcloud Redis Password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your password):"  REDIS_PASSWORD

if [ -z "$REDIS_PASSWORD" ]
then

      echo "${RED}Nextcloud Redis Password cannot be empty ${RESET}"
      exit
fi

read -p "Enter the Nextcloud Hostname you wish to use (Example: cloud):"  NEXTCLOUD_HOSTNAME

if [ -z "$NEXTCLOUD_HOSTNAME" ]
then
      echo "${RED}Nextcloud Hostname cannot be empty ${RESET}"
      exit
fi

#Export the variable
export NEXTCLOUD_HOSTNAME

read -p "Enter the Nextcloud Subdomain you wish to use (Example: domain.tld):"  NEXTCLOUD_DOMAIN

if [ -z "$NEXTCLOUD_DOMAIN" ]
then
   
      echo "${RED}Nextcloud Subdomain cannot be empty ${RESET}"
      exit
fi

#Export the variable
export NEXTCLOUD_DOMAIN

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

read -p "Enter the full path to an EXISTING directory where your Nextcloud Data will reside without an ending slash / (Example: /mnt/data):"  NEXTCLOUD_DATA_PATH

if [ -z "$NEXTCLOUD_DATA_PATH" ]
then
   
      echo "${RED}Nextcloud Data Path cannot be empty ${RESET}"
      exit
fi

#Export the variable
export NEXTCLOUD_DATA_PATH

#Check if /opt/$SITE_NAME-nextcloud exists and if not create it
if [ ! -d "/opt/$SITE_NAME-nextcloud" ]; then
      /bin/mkdir -p /opt/$SITE_NAME-nextcloud
      echo "/opt/$SITE_NAME-nextcloud directory does not exist. Creating...."
   fi

#Check if /opt/$SITE_NAME-nextcloud exists and if not exit
if [ ! -d "/opt/$SITE_NAME-nextcloud" ]; then
      echo "${RED}The /opt/$SITE_NAME-nextcloud directory does not exist even after attempting to create automatically. Exiting for now... ${RESET}"
      exit 1
   fi

echo "Creating Nextcloud Data directories in $NEXTCLOUD_DATA_PATH/$SITE_NAME"
echo "[`date +%m/%d/%Y-%H:%M`] Creating Nextcloud Data directories in $NEXTCLOUD_DATA_PATH/$SITE_NAME" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
#Create necessary directories and setting permissions
/bin/mkdir -p $NEXTCLOUD_DATA_PATH/$SITE_NAME && \
/bin/mkdir -p $NEXTCLOUD_DATA_PATH/$SITE_NAME/db && \
/bin/mkdir -p $NEXTCLOUD_DATA_PATH/$SITE_NAME/db_backups && \
/bin/mkdir -p $NEXTCLOUD_DATA_PATH/$SITE_NAME/nextcloud && \
/bin/mkdir -p $NEXTCLOUD_DATA_PATH/$SITE_NAME/shares && \
/bin/mkdir -p $NEXTCLOUD_DATA_PATH/$SITE_NAME/redis 2>> $SCRIPTPATH/install_log-$TIMESTAMP.log
#/bin/chown -R 1001:1001 $NEXTCLOUD_DATA_PATH/$SITE_NAME 2>> $SCRIPTPATH/install_log-$TIMESTAMP.log

 

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating Nextcloud Data directories in $NEXTCLOUD_DATA_PATH/$SITE_NAME ${RESET}"
        exit 1
fi

if [ "${SMB_SUPPORT}" == "Yes" ]; then

echo "Creating docker-compose.yml file with SMB/CIFS Support"
echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file with SMB/CIFS Support" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp $SCRIPTPATH/templates/nextcloud-docker-compose-template-smb.yml /opt/$SITE_NAME-nextcloud/docker-compose.yml

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating docker-compose.yml file with SMB/CIFS Support ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating docker-compose.yml file with SMB/CIFS Support" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

else

echo "Creating docker-compose.yml file without SMB/CIFS Support"
echo "[`date +%m/%d/%Y-%H:%M`] Creating docker-compose.yml file without SMB/CIFS Support" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/cp $SCRIPTPATH/templates/nextcloud-docker-compose-template.yml /opt/$SITE_NAME-nextcloud/docker-compose.yml

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating docker-compose.yml file without SMB/CIFS Support ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating docker-compose.yml file without SMB/CIFS Support" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

fi


echo "Creating /opt/$SITE_NAME-nextcloud/.env file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/$SITE_NAME-nextcloud/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

#create /opt/guacamole/.env
/bin/cp -r $SCRIPTPATH/templates/.env-template /opt/$SITE_NAME-nextcloud/.env

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating /opt/$SITE_NAME-nextcloud/.env file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating /opt/$SITE_NAME-nextcloud/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Creating /opt/$SITE_NAME-nextcloud/db.env file"
echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/$SITE_NAME-nextcloud/db.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

#create /opt/$SITE_NAME-nextcloud/db.env
/bin/cp -r $SCRIPTPATH/templates/db.env-template /opt/$SITE_NAME-nextcloud/db.env

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Creating db.env-template/db.env file ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Creating /opt/$SITE_NAME-nextcloud/db.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

#=== CONFIGURE /opt/$SITE_NAME-nextcloud/.env STARTS HERE ===
#echo "Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Site Name"
#echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Site Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

#/bin/sed -i -e "s,NEXTCLOUDSITENAME,${SITE_NAME},g" "/opt/$SITE_NAME-nextcloud/.env"

#if [ $? -eq 0 ]; then
#    echo "${GREEN}Done ${RESET}"
#else
#        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud site Name ${RESET}"
#        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Site Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
#        exit
#fi

echo "Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Admin Username"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Admin Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,NEXTCLOUDUSERNAME,${NEXTCLOUD_USERNAME},g" "/opt/$SITE_NAME-nextcloud/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Admin Username ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Admin Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Admin Password"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Admin Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,NEXTCLOUDPASSWORD,${NEXTCLOUD_PASSWORD},g" "/opt/$SITE_NAME-nextcloud/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Admin Password ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Admin Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Redis Password"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Redis Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,REDISPASSWORD,${REDIS_PASSWORD},g" "/opt/$SITE_NAME-nextcloud/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Redis Password ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Redis Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Hostname"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Hostname" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,NEXTCLOUDHOSTNAME,${NEXTCLOUD_HOSTNAME},g" "/opt/$SITE_NAME-nextcloud/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Hostname ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloudnost Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Subdomain"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Subdomain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,NEXTCLOUDDOMAIN,${NEXTCLOUD_DOMAIN},g" "/opt/$SITE_NAME-nextcloud/.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Subdomain ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-nextcloud/.env file with Nextcloud Subdomain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

#=== CONFIGURE /opt/$SITE_NAME-nextcloud/.env ENDS HERE ===

#=== CONFIGURE /opt/$SITE_NAME-nextcloud/db.env STARTS HERE ===

echo "Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Root Password"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Root Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,MYSQLROOTPASSWORD,${MYSQL_ROOT_PASSWORD},g" "/opt/$SITE_NAME-nextcloud/db.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Root Password ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Root Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Name"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,MYSQLDATABASE,${MYSQL_DATABASE},g" "/opt/$SITE_NAME-nextcloud/db.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Name ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Username"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,MYSQLUSERNAME,${MYSQL_USERNAME},g" "/opt/$SITE_NAME-nextcloud/db.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Username ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Username" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Password"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,MYSQLPASSWORD,${MYSQL_PASSWORD},g" "/opt/$SITE_NAME-nextcloud/db.env"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Password ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Error Configuring /opt/$SITE_NAME-nextcloud/db.env file with MySQL/MariaDB Nextcloud Database Password" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi


#=== CONFIGURE /opt/$SITE_NAME-nextcloud/db.env ENDS HERE ===

#=== CONFIGURE /opt/$SITE_NAME-nextcloud/docker-compose.yml ENDS HERE ===


echo "Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with network name of Traefik container"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,TRAEFIKNETWORK,${TRAEFIK_NETWORK},g" "/opt/$SITE_NAME-nextcloud/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with network name of Traefik container ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with network name of Traefik container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

echo "Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with Nextcloud Site Name"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with Nextcloud Site Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,SITENAME,${SITE_NAME},g" "/opt/$SITE_NAME-nextcloud/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with Nextcloud Site Name ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with Nextcloud Site Name" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi


echo "Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with Nextcloud Data Path"
echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with Nextcloud Data Path" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

/bin/sed -i -e "s,NEXTCLOUDDATAPATH,${NEXTCLOUD_DATA_PATH},g" "/opt/$SITE_NAME-nextcloud/docker-compose.yml"

if [ $? -eq 0 ]; then
    echo "${GREEN}Done ${RESET}"
else
        echo "${RED}Error Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with Nextcloud Data Path ${RESET}"
        echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/$SITE_NAME-nextcloud/docker-compose.yml file with Nextcloud Data Path" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
        exit
fi

#=== CONFIGURE /opt/$SITE_NAME-nextcloud/docker-compose.yml ENDS HERE ===


            echo "Starting Nextcloud Docker Container"
            echo "[`date +%m/%d/%Y-%H:%M`] Starting Nextcloud Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

            cd /opt/$SITE_NAME-nextcloud && /usr/local/bin/docker-compose up -d

            if [ $? -eq 0 ]; then
            echo "${GREEN}Done ${RESET}"
            else
            echo "${RED}Error Starting Nextcloud Docker Container ${RESET}"
            echo "[`date +%m/%d/%Y-%H:%M`] Error Starting Nextcloud Docker Container" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
            exit
            fi

            echo "FINISHED INSTALLATION. ENSURE NEXTCLOUD DOCKER CONTAINER IS UP AND RUNNING" | boxes -d stone -p a2v1
            echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE NEXTCLOUD DOCKER CONTAINER IS UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log
            echo "Access Nextcloud by navigating with your web browser to https://$NEXTCLOUD_HOSTNAME.$NEXTCLOUD_DOMAIN"  | boxes -d stone -p a2v1











