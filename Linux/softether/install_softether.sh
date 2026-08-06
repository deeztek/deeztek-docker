#!/bin/bash
#
# Installs SoftEther VPN Server with automatic Let's Encrypt renewal into
# /opt/softether. Ofelia runs certbot nightly; when a certificate is actually
# renewed it is pushed into SoftEther with vpncmd and the server is restarted.
#
# Safe to re-run: previous answers in /opt/softether/.env become the defaults.

#Resolve this script's own directory so it can be run from any working
#directory. Templates, spinner.sh, common.sh and lib/providers.sh are read
#relative to it, and the install log is written into it.
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

#Shared helpers: banner, set_colours, check_prereq, detect_pkg_manager
source "$SCRIPTPATH/common.sh"
source "$SCRIPTPATH/spinner.sh"
#Per-provider certbot credential fields, taken from each plugin's own source
source "$SCRIPTPATH/lib/providers.sh"

#Set Font Colors
set_colours

BASE=/opt/softether
CERTBOT_VERSION=v5.7.0

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
   echo "${RED}The docker compose plugin does not seem to be installed. Install it, or run Linux/docker/ubuntu_install_docker_compose.sh from this repository, and try again. Exiting for now... ${RESET}"
exit 1
fi

#Set install_log Date/Time Stamp
TIMESTAMP=`date +%m-%d-%Y-%H%M`
LOG=$SCRIPTPATH/install_log-$TIMESTAMP.log

echo "SoftEther VPN Installation" | banner

#Re-run friendly: prior answers become the defaults.
if [ -f "$BASE/.env" ]; then
   echo "${GREEN}Existing install found at $BASE, its settings will be offered as defaults ${RESET}"
   set -a; . "$BASE/.env"; set +a
fi

#=== ask <var> <prompt> <default> ===
ask() {
  local __v=$1 __p=$2 __d=${3:-} __in
  if [ -n "$__d" ]; then
     read -r -p "$__p [$__d]: " __in
     __in=${__in:-$__d}
  else
     while [ -z "${__in:-}" ]; do read -r -p "$__p: " __in; done
  fi
  printf -v "$__v" '%s' "$__in"
}

#=== ask_secret <var> <prompt> ===
#Input is hidden; used for API keys and passwords.
ask_secret() {
  local __v=$1 __p=$2 __in=""
  while [ -z "$__in" ]; do read -r -s -p "$__p: " __in; echo; done
  printf -v "$__v" '%s' "$__in"
}

#=== choose <var> <prompt> <options...> ===
choose() {
  local __v=$1 __p=$2; shift 2
  local opts=("$@") i n=""
  echo ""
  echo "$__p"
  for i in "${!opts[@]}"; do printf '  %2d) %s\n' $((i+1)) "${opts[$i]}"; done
  while ! [[ $n =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt ${#opts[@]} ]; do
    read -r -p "Please Select Option [1-${#opts[@]}]: " n
  done
  printf -v "$__v" '%s' "${opts[$((n-1))]}"
}

#=== GET USER INPUTS STARTS HERE ===

#--- platform ---------------------------------------------------------------
#The images are multi-arch. Detect from uname but let the operator override,
#for example when running 64-bit capable hardware on a 32-bit userland.
case "$(uname -m)" in
  aarch64|arm64) DETECTED=linux/arm64 ;;
  x86_64|amd64)  DETECTED=linux/amd64 ;;
  armv7l)        DETECTED=linux/arm/v7 ;;
  *)             DETECTED=linux/amd64 ;;
esac
echo ""
echo "Detected platform: ${GREEN}${DETECTED}${RESET} (uname -m = $(uname -m))"

#List the detected platform first so it is option 1, then the rest, skipping the
#detected one so it is not offered twice.
PLATFORM_OPTS=("$DETECTED")
for p in linux/arm64 linux/amd64 linux/arm/v7; do
  [ "$p" = "$DETECTED" ] || PLATFORM_OPTS+=("$p")
done

choose TARGET_PLATFORM "Which platform should the images run as?" "${PLATFORM_OPTS[@]}"

#--- identity ---------------------------------------------------------------
echo ""
ask VPN_DOMAIN "Enter the full SoftEther VPN FQDN (Example: vpn.domain.tld)" "${VPN_DOMAIN:-}"
ask LE_EMAIL   "Enter an email address for Let's Encrypt expiry notices" "${LE_EMAIL:-}"

#--- validation method ------------------------------------------------------
echo ""
echo "http-01 needs inbound TCP/80 on this host and a public A record."
echo "dns-01  needs API access to your DNS provider, and is the only option"
echo "        that works behind NAT, without port 80, or for wildcards."
choose CERT_METHOD "How should Let's Encrypt validate ${VPN_DOMAIN}?" dns-01 http-01

DNS_PROVIDER=""
mkdir -p $BASE/secrets

if [ "$CERT_METHOD" = "dns-01" ]; then
   choose DNS_PROVIDER "Which DNS provider hosts ${VPN_DOMAIN}?" $DNS_PROVIDERS
   echo ""
   echo "${GREEN}$(provider_label "$DNS_PROVIDER")${RESET}"
   echo "$(provider_hint "$DNS_PROVIDER")"
   echo ""

   if [ "$DNS_PROVIDER" = "cloudflare" ]; then
      choose CF_AUTH "Cloudflare authentication style?" token global-key
      export CF_AUTH
   fi

   STYLE=$(provider_cred_style "$DNS_PROVIDER")
   case $STYLE in
     json)
       ask GOOGLE_KEY_SRC "Path to the Google service account JSON file" ""
       if [ ! -f "$GOOGLE_KEY_SRC" ]; then
          echo "${RED}No such file: $GOOGLE_KEY_SRC. Exiting... ${RESET}"; exit 1
       fi
       cp "$GOOGLE_KEY_SRC" "$BASE/secrets/${DNS_PROVIDER}.json"
       chmod 600 "$BASE/secrets/${DNS_PROVIDER}.json"
       echo "${GREEN}Wrote $BASE/secrets/${DNS_PROVIDER}.json ${RESET}"
       ;;
     ini|env)
       CREDFILE="$BASE/secrets/${DNS_PROVIDER}.ini"
       [ "$STYLE" = "env" ] && CREDFILE="$BASE/secrets/${DNS_PROVIDER}.env"
       TMPCRED=$(mktemp); chmod 600 "$TMPCRED"
       [ "$STYLE" = "ini" ] && echo "# certbot ${DNS_PROVIDER} credentials, written by install_softether.sh" >> "$TMPCRED"
       #Collect the field list FIRST. Looping with `while read ... < <(...)`
       #would point the loop body's stdin at the field list, so the prompts
       #inside would consume field definitions as answers instead of the user.
       FIELDS=()
       while IFS= read -r line; do
         [ -n "$line" ] && FIELDS+=("$line")
       done < <(provider_fields "$DNS_PROVIDER")
       for line in "${FIELDS[@]}"; do
         IFS='|' read -r key prompt secret default <<<"$line"
         if [ "$secret" = "s" ]; then ask_secret VAL "$prompt"
         else ask VAL "$prompt" "$default"; fi
         if [ "$STYLE" = "env" ]; then echo "${key}=${VAL}" >> "$TMPCRED"
         else echo "${key} = ${VAL}" >> "$TMPCRED"; fi
       done
       mv "$TMPCRED" "$CREDFILE"; chmod 600 "$CREDFILE"
       echo "${GREEN}Wrote $CREDFILE (mode 600) ${RESET}"
       ;;
   esac

   ask DNS_PROPAGATION "Seconds to wait for DNS propagation" \
       "${DNS_PROPAGATION:-$(provider_propagation "$DNS_PROVIDER")}"
else
   echo "${RED}Ensure TCP/80 is free on this host and reachable from the Internet. ${RESET}"
   DNS_PROPAGATION=0
fi

#--- staging vs production --------------------------------------------------
echo ""
echo "Staging issues untrusted certificates but has generous rate limits. Use it"
echo "to prove the whole pipeline works before spending production quota."
choose LE_ENV "Which Let's Encrypt environment for the first certificate?" staging production
CERT_STAGING=false
[ "$LE_ENV" = "staging" ] && CERT_STAGING=true

#--- SoftEther admin password ----------------------------------------------
echo ""
echo "The SoftEther server administration password. If you are dropping in an"
echo "existing vpn_server.config, enter that server's EXISTING password -- the"
echo "hash travels inside the file (byte HashedPassword)."
if [ -f "$BASE/secrets/se-admin.pw" ]; then
   echo "${GREEN}Using existing $BASE/secrets/se-admin.pw ${RESET}"
else
   ask_secret SE_PW "Enter the SoftEther server administration password"
   printf '%s\n' "$SE_PW" > "$BASE/secrets/se-admin.pw"
fi
chmod 600 "$BASE/secrets/se-admin.pw"
ADMIN_PW="$(head -n 1 "$BASE/secrets/se-admin.pw" | tr -d '\r\n')"

#=== GET USER INPUTS ENDS HERE ===

if [ "$CERT_METHOD" = "dns-01" ]; then
   CERTBOT_IMAGE="certbot/dns-${DNS_PROVIDER}:${CERTBOT_VERSION}"
else
   CERTBOT_IMAGE="certbot/certbot:${CERTBOT_VERSION}"
fi

#--- create the directory tree ----------------------------------------------
echo "[`date +%m/%d/%Y-%H:%M`] Creating $BASE directories" >> $LOG 2>&1
start_spinner "Creating $BASE directories..."
sleep 1
mkdir -p $BASE/softether_config/data $BASE/softether_config/logs \
         $BASE/certbot/conf $BASE/certbot/lib $BASE/certbot/logs \
         $BASE/ofelia $BASE/scripts $BASE/secrets >> $LOG 2>&1
chmod 700 $BASE/secrets >> $LOG 2>&1
stop_spinner $?

#--- .env -------------------------------------------------------------------
echo "[`date +%m/%d/%Y-%H:%M`] Creating $BASE/.env file" >> $LOG 2>&1
start_spinner "Creating $BASE/.env file..."
sleep 1
cat > $BASE/.env <<EOF
#Written by install_softether.sh -- re-run it to change these.
TARGET_PLATFORM=$TARGET_PLATFORM
VPN_DOMAIN=$VPN_DOMAIN
LE_EMAIL=$LE_EMAIL
CERT_METHOD=$CERT_METHOD
DNS_PROVIDER=$DNS_PROVIDER
DNS_PROPAGATION=$DNS_PROPAGATION
CERTBOT_IMAGE=$CERTBOT_IMAGE
CERT_STAGING=$CERT_STAGING
EOF
chmod 600 $BASE/.env >> $LOG 2>&1
stop_spinner $?

#--- docker-compose.yml -----------------------------------------------------
echo "[`date +%m/%d/%Y-%H:%M`] Creating $BASE/docker-compose.yml file" >> $LOG 2>&1
start_spinner "Creating $BASE/docker-compose.yml file..."
sleep 1
cp $SCRIPTPATH/templates/softether-docker-compose-template.yml $BASE/docker-compose.yml >> $LOG 2>&1
stop_spinner $?

#--- renew script -----------------------------------------------------------
echo "[`date +%m/%d/%Y-%H:%M`] Creating $BASE/scripts/certbot_renew.sh file" >> $LOG 2>&1
start_spinner "Creating $BASE/scripts/certbot_renew.sh file..."
sleep 1
cp $SCRIPTPATH/templates/certbot_renew-template $BASE/scripts/certbot_renew.sh >> $LOG 2>&1 && \
chmod 0755 $BASE/scripts/certbot_renew.sh >> $LOG 2>&1
stop_spinner $?

#--- ofelia config ----------------------------------------------------------
#Generated rather than copied: ofelia talks to the Docker API directly and
#cannot resolve relative paths, so the absolute BASE has to be substituted in.
echo "[`date +%m/%d/%Y-%H:%M`] Creating $BASE/ofelia/config.ini file" >> $LOG 2>&1
start_spinner "Creating $BASE/ofelia/config.ini file..."
sleep 1
sed "s|__BASE__|${BASE}|g" $SCRIPTPATH/templates/config.ini-template > $BASE/ofelia/config.ini 2>> $LOG
stop_spinner $?

#--- start SoftEther --------------------------------------------------------
echo "[`date +%m/%d/%Y-%H:%M`] Starting the SoftEther container" >> $LOG 2>&1
start_spinner "Starting the SoftEther container..."
cd $BASE >> $LOG 2>&1 && \
docker compose up -d vpnserver >> $LOG 2>&1 && \
timeout 90 bash -c "until docker exec softether-vpnserver \
  ls /var/lib/softether/vpn_server.config >/dev/null 2>&1; do sleep 1; done" >> $LOG 2>&1
stop_spinner $?

if ! docker ps --format '{{.Names}}' | grep -q '^softether-vpnserver$'; then
   echo "${RED}SoftEther did not start. See $LOG. Exiting... ${RESET}"
   exit 1
fi

#=== se_auth_ok <password> ===
#
#vpncmd does NOT exit on a bad password -- it prints "Access has been denied"
#and then blocks forever on an interactive "Password:" prompt, even with stdin
#closed. Every call is wrapped in timeout so a wrong password fails instead of
#hanging the installer.
se_auth_ok() {
  local out rc=0
  out="$(timeout 30 docker exec softether-vpnserver /usr/local/bin/vpncmd localhost \
    /SERVER /PASSWORD:"$1" /CMD ServerStatusGet 2>&1)" || rc=$?
  [ $rc -eq 0 ] && ! echo "$out" | grep -q "Access has been denied"
}

echo ""
echo "Checking the SoftEther administration password"
if se_auth_ok "$ADMIN_PW"; then
   echo "${GREEN}$BASE/secrets/se-admin.pw already matches the server ${RESET}"
else
   FOUND=""; SET_FROM=""
   for candidate in "" "${SE_CURRENT_PASSWORD:-}"; do
     if se_auth_ok "$candidate"; then FOUND=1; SET_FROM="$candidate"; break; fi
   done
   if [ -z "$FOUND" ]; then
      echo "${RED}Cannot authenticate to the SoftEther server."
      echo "The password you supplied is not the server's administration password,"
      echo "and neither is the blank one. If you copied in an existing"
      echo "vpn_server.config, its password came with it (byte HashedPassword)."
      echo "Put that password in $BASE/secrets/se-admin.pw, or re-run as:"
      echo "    SE_CURRENT_PASSWORD='<existing>' $0"
      echo "Exiting... ${RESET}"
      exit 1
   fi
   start_spinner "Setting the SoftEther administration password..."
   timeout 30 docker exec softether-vpnserver /usr/local/bin/vpncmd localhost /SERVER \
     /PASSWORD:"$SET_FROM" /CMD ServerPasswordSet "$ADMIN_PW" >> $LOG 2>&1 && \
   timeout 30 docker exec softether-vpnserver /usr/local/bin/vpncmd localhost /SERVER \
     /PASSWORD:"$ADMIN_PW" /CMD Flush >> $LOG 2>&1
   stop_spinner $?
   if ! se_auth_ok "$ADMIN_PW"; then
      echo "${RED}The password change did not take. See $LOG. Exiting... ${RESET}"
      exit 1
   fi
   echo "${GREEN}Administration password set and flushed ${RESET}"
fi

#--- dry run gate -----------------------------------------------------------
#Prove the credentials and the ACME round trip before spending any production
#quota. A wrong API key costs nothing here.
echo ""
echo "Testing the certbot pipeline against the Let's Encrypt staging environment"
echo "(dry run, no rate limit cost, nothing is changed)"
echo ""
#PIPESTATUS, not the pipeline's status: piping into tee makes the exit status
#tee's, which is always 0, so a failed dry run would look like a success and
#this gate would never fire.
$BASE/scripts/certbot_renew.sh --dry-run 2>&1 | tee -a $LOG
if [ ${PIPESTATUS[0]} -eq 0 ]; then
   echo "${GREEN}Dry run succeeded ${RESET}"
else
   echo "${RED}The certbot dry run failed. Fix the problem reported above before"
   echo "issuing a real certificate. Nothing has been changed on the VPN server."
   echo "Re-run this script when ready. Exiting... ${RESET}"
   exit 1
fi

#--- issue ------------------------------------------------------------------
echo ""
echo "Requesting the ${LE_ENV} certificate for ${VPN_DOMAIN}"
echo ""
$BASE/scripts/certbot_renew.sh 2>&1 | tee -a $LOG
if [ ${PIPESTATUS[0]} -ne 0 ]; then
   echo "${RED}Certificate issuance failed. See $LOG. Exiting... ${RESET}"
   exit 1
fi

#--- start the scheduler ----------------------------------------------------
echo "[`date +%m/%d/%Y-%H:%M`] Starting the ofelia scheduler" >> $LOG 2>&1
start_spinner "Starting the ofelia scheduler..."
cd $BASE >> $LOG 2>&1 && docker compose up -d >> $LOG 2>&1
stop_spinner $?

echo ""
echo "SoftEther VPN Installation Complete" | banner
cat <<EOF

  Installed to:     $BASE
  Nightly renewal:  03:17, see $BASE/ofelia/config.ini
  Test any time:    $SCRIPTPATH/certbot_test.sh    (staging dry run)
  Force a renewal:  $BASE/scripts/certbot_renew.sh --force
  Scheduler log:    docker logs softether-ofelia
  Install log:      $LOG

  Confirm what clients actually get:
    echo | openssl s_client -connect ${VPN_DOMAIN}:443 -servername ${VPN_DOMAIN} 2>/dev/null \\
      | openssl x509 -noout -subject -issuer -dates

EOF

if [ "$CERT_STAGING" = "true" ]; then
   echo "${RED}This is a STAGING certificate and clients will not trust it."
   echo "Re-run this script and pick \"production\" when you are ready. ${RESET}"
   echo ""
fi
