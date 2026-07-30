#!/bin/bash

#Set Font Colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`

#The script below assumes a fully installed and updated Linux server with the
#docker engine and the docker compose plugin already installed.
#
#The prerequisites below (boxes, git, curl, openssl) are installed
#automatically with apt-get on Debian and Ubuntu. On other distributions,
#install them with your own package manager first and the script will use them.

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then
      echo "${RED}This script must be executed as root, Exiting... ${RESET}"
      exit 1
   fi

#Check if docker exists and if not exit
if command -v docker > /dev/null 2>&1; then
  echo "${GREEN}Docker Exists! Proceeding... ${RESET}"
else
   echo "${RED}Docker does not seem to be installed. Please install Docker and try again. Exiting for now... ${RESET}"
exit 1
fi

#Check if the docker compose plugin exists and if not exit
if docker compose version > /dev/null 2>&1; then
  echo "${GREEN}Docker Compose Exists! Proceeding... ${RESET}"
else
   echo "${RED}The docker compose plugin does not seem to be installed. Please run ubuntu_install_docker_compose.sh and try again. Exiting for now... ${RESET}"
exit 1
fi

#Tracks whether "apt-get update" has already been run this session
APT_UPDATED=0

#check_prereq <command> <debian package providing it>
#Uses the command if already present, installs it with apt-get if not, and
#exits with a clear message if neither is possible.
check_prereq() {
  PREREQ_CMD=$1
  PREREQ_PKG=$2

  if command -v $PREREQ_CMD > /dev/null 2>&1; then
     echo "${GREEN}$PREREQ_CMD Exists! Proceeding... ${RESET}"
     return 0
  fi

  if ! command -v apt-get > /dev/null 2>&1; then
     echo "${RED}$PREREQ_CMD is required but is not installed, and apt-get is not available to install it. Please install the $PREREQ_PKG package with your distribution's package manager and run this script again. Exiting... ${RESET}"
     exit 1
  fi

  if [ $APT_UPDATED -eq 0 ]; then
     echo "Updating Package Lists"
     apt-get update > /dev/null 2>&1
     APT_UPDATED=1
  fi

  echo "Installing $PREREQ_PKG Prerequisite"
  apt-get install $PREREQ_PKG -y > /dev/null 2>&1

  if ! command -v $PREREQ_CMD > /dev/null 2>&1; then
     echo "${RED}Failed to install $PREREQ_PKG. Exiting... ${RESET}"
     exit 1
  fi

  echo "${GREEN}Done ${RESET}"
}

#boxes formats the banner output, git clones the upstream repo (for the Janus
#image and gnatsd.conf), curl auto-detects the public IP, openssl generates the
#secrets and self signed certificates.
check_prereq boxes boxes
check_prereq git git
check_prereq curl curl
check_prereq openssl openssl


#Set the script path
SCRIPTPATH=$(pwd)

#Upstream release to check out. Must match the image tag used for the
#spreedbackend service in templates/nextcloud-signal-docker-compose-template.yml
SIGNAL_VERSION="v2.1.1"
export SIGNAL_VERSION

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

#Auto-detect the public IP address to offer as the default
DETECTED_IP=`curl -s --max-time 10 https://ifconfig.me 2>/dev/null`

read -p "Enter the PUBLIC IP address of this server. This is advertised to clients in ICE candidates and TURN relay addresses [${DETECTED_IP}]:"  PUBLIC_IP

if [ -z "$PUBLIC_IP" ]
then
      PUBLIC_IP=$DETECTED_IP
fi

if [ -z "$PUBLIC_IP" ]
then

      echo "${RED}Public IP address cannot be empty and could not be auto-detected ${RESET}"
      exit
fi

#Export the variable
export PUBLIC_IP

echo ""
echo "If this server has multiple public IP addresses, published ports can be"
echo "bound to a single one so the stack does not claim ports on the others."

#BIND_SPECIFIC controls whether published ports get an IP prefix at all. When 0,
#the "${BIND_IP}:" prefix is stripped from docker-compose.yml entirely, leaving
#plain "80:80" style mappings rather than assuming "0.0.0.0:80:80".
BIND_SPECIFIC=0
BIND_IP="0.0.0.0"

PS3='Bind published ports to a specific IP address?: '
options=("No - listen on all interfaces" "Yes - bind to a specific IP address")
select opt in "${options[@]}"
do
    case $opt in
        "No - listen on all interfaces")

            BIND_SPECIFIC=0

          break
            ;;
        "Yes - bind to a specific IP address")

            read -p "Enter the IP address to bind published ports to [${PUBLIC_IP}]:"  BIND_IP

            if [ -z "$BIND_IP" ]
            then
                  BIND_IP=$PUBLIC_IP
            fi

            #Verify the chosen bind address actually exists on this host
            if ! ip -o addr show | grep -qw "$BIND_IP"; then
                  echo "${RED}$BIND_IP is not configured on any interface of this host. Exiting... ${RESET}"
                  exit 1
            fi

            BIND_SPECIFIC=1

          break
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

if [ $BIND_SPECIFIC -eq 1 ]; then
   BIND_DESCRIPTION="Published ports are bound to $BIND_IP only."
else
   BIND_DESCRIPTION="Published ports listen on all interfaces."
fi

#Export the variables
export BIND_IP
export BIND_SPECIFIC
export BIND_DESCRIPTION

#=== GET USER INPUTS ENDS HERE ===

source "$SCRIPTPATH/spinner.sh"

echo "[`date +%m/%d/%Y-%H:%M`] Git cloning nextcloud-spreed-signaling to /opt/nextcloud-spreed-signaling" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Git cloning nextcloud-spreed-signaling to /opt/nextcloud-spreed-signaling...'
sleep 1

#The repo is cloned to build the Janus image (docker/janus, Janus 1.3.0) and to
#provide gnatsd.conf. The signaling server itself uses the prebuilt image, so
#this is pinned to the release matching the image tag in docker-compose.yml.
cd /opt/ >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
git clone --branch $SIGNAL_VERSION https://github.com/strukturag/nextcloud-spreed-signaling.git >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CREATING FILES STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/nextcloud-spreed-signaling/.gitignore file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating .gitignore file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/.gitignore
cp -r $SCRIPTPATH/templates/.gitignore-template /opt/nextcloud-spreed-signaling/.gitignore >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/nextcloud-spreed-signaling/.env file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating .env file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/.env
cp -r $SCRIPTPATH/templates/.env-template /opt/nextcloud-spreed-signaling/.env >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/nextcloud-spreed-signaling/coturn directory" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating coturn directory...'
sleep 1

#create /opt/nextcloud-spreed-signaling/.env
mkdir -p /opt/nextcloud-spreed-signaling/coturn >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/nextcloud-spreed-signaling/coturn/fullchain.pem and /opt/nextcloud-spreed-signaling/coturn/privkey.pem placeholder files" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Generating Self Signed Certificate for Coturn...'
sleep 1

#Generate a self signed certificate for coturn. Empty placeholder files would
#stop coturn from bringing up its TLS/DTLS listener, so turns: would not work
#at all until Lets Encrypt ran. certbot_certificate_production.sh and
#certbot_renew.sh overwrite these with the real certificate.
openssl req -batch -x509 -newkey rsa:4096 -nodes -subj "/CN=$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN" -keyout /opt/nextcloud-spreed-signaling/coturn/privkey.pem -out /opt/nextcloud-spreed-signaling/coturn/fullchain.pem -sha256 -days 1825 >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

start_spinner 'Setting Coturn certificate permissions...'
sleep 1

#0755 on the directory so the container can traverse it, 0644 on the files.
chmod 0755 /opt/nextcloud-spreed-signaling/coturn >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
chmod 0644 /opt/nextcloud-spreed-signaling/coturn/fullchain.pem /opt/nextcloud-spreed-signaling/coturn/privkey.pem >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/nextcloud-spreed-signaling/server.conf file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating server.conf file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/server.conf
cp -r $SCRIPTPATH/templates/server-template.conf /opt/nextcloud-spreed-signaling/server.conf >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/docker-compose.yml file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating docker-compose.yml...'
sleep 1

cp $SCRIPTPATH/templates/nextcloud-signal-docker-compose-template.yml /opt/nextcloud-spreed-signaling/docker-compose.yml >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Creating /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default.conf file" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating Nginx default site file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/nginx/conf/nginx/default
cp -rf $SCRIPTPATH/nginx/ /opt/nextcloud-spreed-signaling/nginx/ >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Creating Certbot Certificate Directory Structure" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Creating Creating Certbot Certificate Directory Structure...'
sleep 1

#create /opt/nextcloud-spreed-signaling/certbot/conf/dummy directory
mkdir -p /opt/nextcloud-spreed-signaling/certbot >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/conf >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/ofelia >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/scripts >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/nginx/conf/www >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/conf/renewal-hooks >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/conf/renewal-hooks/deploy >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/conf/renewal-hooks/post >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/conf/renewal-hooks/pre >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/logs >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/conf/dummy >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
mkdir -p /opt/nextcloud-spreed-signaling/certbot/conf/dummy/$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Generating Self Signed Certificate for Nginx" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Generating Self Signed Certificate for Nginx...'
sleep 1

#generate self signed cert for Nginx
openssl req -batch -x509 -newkey rsa:4096 -nodes -keyout /opt/nextcloud-spreed-signaling/certbot/conf/dummy/$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN/privkey.pem -out /opt/nextcloud-spreed-signaling/certbot/conf/dummy/$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN/fullchain.pem -sha256 -days 1825 >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

start_spinner 'Creating certbot_renew.sh file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/scripts/certbot_renew.sh
cp -r $SCRIPTPATH/templates/certbot_renew-template /opt/nextcloud-spreed-signaling/scripts/certbot_renew.sh >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

start_spinner 'Making certbot_renew.sh file executable...'
sleep 1

#Make /opt/nextcloud-spreed-signaling/scripts/certbot_renew.sh executable
chmod +x /opt/nextcloud-spreed-signaling/scripts/certbot_renew.sh >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

start_spinner 'Creating ofelia config.ini file...'
sleep 1

#create /opt/nextcloud-spreed-signaling/ofelia/config.ini
cp -r $SCRIPTPATH/templates/config.ini-template /opt/nextcloud-spreed-signaling/ofelia/config.ini >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CREATING FILES ENDS HERE ===

#=== GENERATING VARIABLES STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Generating Static Secret Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Static Secret Random String...'
sleep 1

STATIC_SECRET=`openssl rand -hex 32` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Static Secret is: $STATIC_SECRET" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Static Secret is:${GREEN} $STATIC_SECRET ${RESET}" | boxes -d stone -p a2v1


echo "[`date +%m/%d/%Y-%H:%M`] Generating Hash Key Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Hash Key Random String...'
sleep 1

#64 chars. The server documents 32 or 64 bytes for the session hash key.
HASH_KEY=`openssl rand -hex 32` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Generating Block Key Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Block Key Random String...'
sleep 1

#32 chars. The server rejects a block key that is not 16, 24 or 32 bytes.
BLOCK_KEY=`openssl rand -hex 16` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Generating Nextcloud Shared Secret Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Nextcloud Shared Secret Random String...'
sleep 1

SHARED_SECRET=`openssl rand -hex 32` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Shared Secret is: $SHARED_SECRET" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Shared Secret is:${GREEN} $SHARED_SECRET ${RESET}" | boxes -d stone -p a2v1

echo "[`date +%m/%d/%Y-%H:%M`] Generating Api Key Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Api Key Random String...'
sleep 1

API_KEY=`openssl rand -hex 16` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Generating Internal Shared Secret Random String" >> $SCRIPTPATH/install_log-$TIMESTAMP.log

start_spinner 'Generating Internal Shared Secret Random String...'
sleep 1

INTERNAL_SECRET=`openssl rand -hex 32` >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== GENERATING VARIABLES ENDS HERE ===

#=== CONFIGURING FILES STARTS HERE ===

#=== CONFIGURE /opt/nextcloud-spreed-signaling/.env STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/.env file with Nextcloud-Signal Hostname" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with Nextcloud-Signal Hostname...'
sleep 1

sed -i -e "s,SIGNALHOSTNAME,${SIGNAL_HOSTNAME},g" "/opt/nextcloud-spreed-signaling/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/.env file with Nextcloud-Signal Domain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with Nextcloud-Signal Domain...'
sleep 1

sed -i -e "s,SIGNALDOMAIN,${SIGNAL_DOMAIN},g" "/opt/nextcloud-spreed-signaling/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/.env file with Static Secret" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with Static Secret...'
sleep 1

sed -i -e "s,STATICSECRET,${STATIC_SECRET},g" "/opt/nextcloud-spreed-signaling/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/.env file with Public IP" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring .env file with Public IP...'
sleep 1

sed -i -e "s,PUBLICIP,${PUBLIC_IP},g" "/opt/nextcloud-spreed-signaling/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

if [ $BIND_SPECIFIC -eq 1 ]; then

echo "[`date +%m/%d/%Y-%H:%M`] Binding published ports to $BIND_IP" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner "Binding published ports to $BIND_IP..."
sleep 1

sed -i -e "s,BINDIP,${BIND_IP},g" "/opt/nextcloud-spreed-signaling/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

else

echo "[`date +%m/%d/%Y-%H:%M`] Publishing ports on all interfaces, removing the bind address prefix" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Publishing ports on all interfaces...'
sleep 1

#No specific bind address was requested, so strip the prefix from every port
#mapping and drop the now-unused variable from .env, rather than assuming
#0.0.0.0 (which would also silently disable IPv6 binding).
sed -i -e 's,[$][{]BIND_IP[}]:,,g' "/opt/nextcloud-spreed-signaling/docker-compose.yml" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1 && \
sed -i -e '/^# BIND_IP:/,/^BIND_IP=BINDIP$/d' "/opt/nextcloud-spreed-signaling/.env" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

fi

#=== CONFIGURE /opt/nextcloud-spreed-signaling/.env ENDS HERE ===

#=== CONFIGURE /opt/nextcloud-spreed-signaling/server.conf STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Hash Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Hash Key...'
sleep 1

sed -i -e "s,HASHKEY,${HASH_KEY},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Block Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Block Key...'
sleep 1

sed -i -e "s,BLOCKKEY,${BLOCK_KEY},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Nextcloud instance URL" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Nextloud instance URL...'
sleep 1

sed -i -e "s,NEXTCLOUDSERVER,${NEXTCLOUD_SERVER},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Nextcloud Static Secret" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Nextcloud Static Secret...'
sleep 1

sed -i -e "s,STATICSECRET,${STATIC_SECRET},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Nextcloud Shared Secret" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Nextcloud Shared Secret...'
sleep 1

sed -i -e "s,SHAREDSECRET,${SHARED_SECRET},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Api Key" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Api Key...'
sleep 1

sed -i -e "s,APIKEY,${API_KEY},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/server.conf file with Internal Shared Secret" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring server.conf file with Internal Shared Secret...'
sleep 1

sed -i -e "s,INTERNALSECRET,${INTERNAL_SECRET},g" "/opt/nextcloud-spreed-signaling/server.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CONFIGURE /opt/nextcloud-spreed-signaling/server.conf ENDS HERE ===

#=== CONFIGURE /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default.conf STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default.conf file with Nextcloud-Signal Hostname" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring Nginx default file with Nextcloud-Signal Hostname...'
sleep 1

sed -i -e "s,SIGNALHOSTNAME,${SIGNAL_HOSTNAME},g" "/opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default.conf file with Nextcloud-Signal Domain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring Nginx default file with Nextcloud-Signal Domain...'
sleep 1

sed -i -e "s,SIGNALDOMAIN,${SIGNAL_DOMAIN},g" "/opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default.conf" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CONFIGURE /opt/nextcloud-spreed-signaling/nginx/conf/nginx/site-confs/default.conf ENDS HERE ===

#=== CONFIGURE /opt/nextcloud-spreed-signaling/scripts/certbot_renew.sh STARTS HERE ===

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/scripts/certbot_renew.sh file with Nextcloud-Signal Hostname" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring cerbot_renew.sh file with Nextcloud-Signal Hostname...'
sleep 1

sed -i -e "s,SIGNALHOSTNAME,${SIGNAL_HOSTNAME},g" "/opt/nextcloud-spreed-signaling/scripts/certbot_renew.sh" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Configuring /opt/nextcloud-spreed-signaling/scripts/certbot_renew.sh file with Nextcloud-Signal Domain" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Configuring cerbot_renew.sh file with Nextcloud-Signal Domain...'
sleep 1

sed -i -e "s,SIGNALDOMAIN,${SIGNAL_DOMAIN},g" "/opt/nextcloud-spreed-signaling/scripts/certbot_renew.sh" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

#=== CONFIGURE /opt/nextcloud-spreed-signaling/scripts/certbot_renew.sh ENDS HERE ===


echo "[`date +%m/%d/%Y-%H:%M`] Building Janus Docker Image. This takes several minutes." >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Building Janus Docker Image (this takes several minutes)...'
sleep 1

cd /opt/nextcloud-spreed-signaling && docker compose build >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?

echo "[`date +%m/%d/%Y-%H:%M`] Pulling Nextcloud-Signal Docker Images" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Pulling Nextcloud-Signal Docker Images...'
sleep 1

cd /opt/nextcloud-spreed-signaling && docker compose pull --ignore-buildable >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "[`date +%m/%d/%Y-%H:%M`] Starting Nextcloud-Signal Docker Containers" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

start_spinner 'Starting Nextcloud-Signal Docker Containers...'
sleep 1

#The spreed network is declared in docker-compose.yml, so compose creates it.
cd /opt/nextcloud-spreed-signaling && docker compose up -d >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

stop_spinner $?


echo "FINISHED INSTALLATION. ENSURE ALL CONTAINERS ARE UP AND RUNNING" | boxes -d stone -p a2v1

echo "[`date +%m/%d/%Y-%H:%M`] FINISHED INSTALLATION. ENSURE ALL CONTAINERS ARE UP AND RUNNING" >> $SCRIPTPATH/install_log-$TIMESTAMP.log 2>&1

echo "Configure Nextcloud (Settings --> Administration --> Talk) with:

  STUN server:            $SIGNAL_HOSTNAME.$SIGNAL_DOMAIN:3478
  TURN server (turns:):   $SIGNAL_HOSTNAME.$SIGNAL_DOMAIN:5349
  TURN secret:            $STATIC_SECRET

  High-performance backend URL:  https://$SIGNAL_HOSTNAME.$SIGNAL_DOMAIN/standalone-signaling/
  High-performance backend secret: $SHARED_SECRET

Open these ports on your firewall:

  80/tcp, 443/tcp                     (nginx, Lets Encrypt http-01)
  3478/tcp, 3478/udp                  (STUN / TURN)
  5349/tcp, 5349/udp                  (TURN over TLS)
  20000-20099/udp                     (Janus media)
  49160-49200/udp                     (Coturn relay)

$PUBLIC_IP is advertised to clients in ICE candidates and TURN relay addresses.
$BIND_DESCRIPTION" | boxes -d stone -p a2v1


