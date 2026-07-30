#!/bin/bash

BASE=/opt/nextcloud-spreed-signaling

#Resolve this script's own directory so it can be run from any working directory
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#Shared helpers: banner, set_colours
source "$SCRIPTPATH/common.sh"

#Set Font Colors
set_colours

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then
      echo "${RED}This script must be executed as root, Exiting... ${RESET}"
      exit 1
   fi

#Check if docker exists and if not exit
if ! command -v docker > /dev/null 2>&1; then
      echo "${RED}Docker does not seem to be installed. Please install Docker and try again. Exiting for now... ${RESET}"
      exit 1
   fi

#Check the installation directory exists
if [ ! -d "$BASE" ]; then
      echo "${RED}$BASE does not exist. Run install_nextcloud_signal.sh first. Exiting... ${RESET}"
      exit 1
   fi


#GET INPUTS
echo "Certbot Certificate Production" | banner

PS3='Ensure that both ports 80/TCP and 443/TCP are Internet accessible and the Signal FQDN you are going to use is pointing to the public IP address of this machine. Do you wish to continue?: '
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
            echo "Starting Certbot Certificate Production"


          break
            ;;
        "No")

            echo "Exiting Certbot Certificate Production";
            exit
            ;;

        *) echo "invalid option $REPLY";;
    esac
done

#=== GET USER INPUTS STARTS HERE ===

#Read the FQDN from the deployed .env rather than asking for it again. A typo
#here would issue a certificate into live/<typo>/ while nginx looks for
#live/<installed fqdn>/, costing a real issuance and leaving nginx unable to
#start on a missing certificate file.
SIGNAL_FQDN=""
if [ -f "$BASE/.env" ]; then
   SIGNAL_FQDN=`grep -E '^SIGNAL_FQDN=' "$BASE/.env" | head -1 | cut -d= -f2- | tr -d '"'"'"'\r' | xargs`
fi

if [ -n "$SIGNAL_FQDN" ]; then
   echo "Using the Nextcloud-Signal FQDN from $BASE/.env: ${GREEN}$SIGNAL_FQDN${RESET}"
   read -p "Press Enter to accept, or type a different FQDN: "  FQDN_OVERRIDE
   if [ -n "$FQDN_OVERRIDE" ]; then
         SIGNAL_FQDN=$FQDN_OVERRIDE
   fi
else
   echo "${RED}Could not read SIGNAL_FQDN from $BASE/.env ${RESET}"
   read -p "Enter the full Nextcloud-Signal FQDN (Example: signal.domain.tld):"  SIGNAL_FQDN
fi

if [ -z "$SIGNAL_FQDN" ]
then
      echo "${RED}Nextcloud-Signal FQDN cannot be empty ${RESET}"
      exit 1
fi

#Cross check against the deployed nginx config. nginx has the name baked in
#from installation time, so if it does not appear there the certificate would
#be issued under a name nginx is not serving.
NGINX_SITE="$BASE/nginx/conf/nginx/site-confs/default.conf"
if [ -f "$NGINX_SITE" ] && ! grep -q "$SIGNAL_FQDN" "$NGINX_SITE"; then
      echo "${RED}Warning: $SIGNAL_FQDN does not appear in $NGINX_SITE ${RESET}"
      echo "${RED}nginx is configured for a different name and will not serve this certificate. ${RESET}"
      read -p "Continue anyway? [y/N]: "  MISMATCH_OK
      case "$MISMATCH_OK" in
        [Yy]*) ;;
        *) echo "Exiting."; exit 1 ;;
      esac
fi

#Export the variable
export SIGNAL_FQDN

echo "Requesting Certbot Certificate Production"

#Collect the Lets Encrypt account details up front. Certbot cannot prompt for
#them from inside "docker run" with no TTY.
CERTBOT_ACCOUNT_ARGS=`certbot_account_args`
if [ $? -ne 0 ]; then
      exit 1
fi

#The webroot must be the directory nginx serves as /config/www, which is
#$BASE/nginx/conf/www on the host. Paths must be absolute for docker run.
docker run --rm --name certbot \
  -v $BASE/nginx/conf/www:/var/www/certbot \
  -v $BASE/certbot/conf/:/etc/letsencrypt \
  -v $BASE/certbot/logs:/var/log/letsencrypt \
  certbot/certbot:latest certonly --webroot --webroot-path /var/www/certbot/ $CERTBOT_ACCOUNT_ARGS -d $SIGNAL_FQDN

ERR=$?
if [ $ERR != 0 ]; then
echo "${RED}Error $ERR, occurred Requesting Certbot Certificate Production ${RESET}"
exit 1
else
echo "${GREEN}Done ${RESET}"
fi

echo "Re-configuring Nginx for Certbot Certificate Production and Restarting Nginx Container"

/bin/sed -i -e "s,/etc/nginx/ssl/dummy/,/etc/nginx/ssl/live/,g" "$BASE/nginx/conf/nginx/site-confs/default.conf" && \
docker container restart nextcloud_spreed_nginx


ERR=$?
if [ $ERR != 0 ]; then
echo "${RED}Error $ERR, occurred Re-configuring Nginx for Certbot Certificate Production and Restarting Nginx Container ${RESET}"
exit 1
else
echo "${GREEN}Done ${RESET}"
fi

echo "Re-configuring Coturn for Certbot Certificate Production and Restarting Coturn Container"

#Copy certificate and private key to coturn
cp $BASE/certbot/conf/live/$SIGNAL_FQDN/fullchain.pem $BASE/coturn/fullchain.pem && \
cp $BASE/certbot/conf/live/$SIGNAL_FQDN/privkey.pem $BASE/coturn/privkey.pem && \

#Set certificate and key permissions. 0755 on the directory so the coturn
#container can traverse it, 0644 on the files themselves. A recursive 0644
#would strip +x from the directory.
chmod 0755 $BASE/coturn && \
chmod 0644 $BASE/coturn/fullchain.pem $BASE/coturn/privkey.pem && \

#Restart Coturn container to load new certificate and key
docker container restart nextcloud_spreed_coturn

ERR=$?
if [ $ERR != 0 ]; then
echo "${RED}Error $ERR, occurred Re-configuring Coturn for Certbot Certificate Production ${RESET}"
exit 1
else
echo "${GREEN}Done ${RESET}"
fi
