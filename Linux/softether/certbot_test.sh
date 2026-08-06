#!/bin/bash
#
# Exercise the whole certbot path against the Let's Encrypt STAGING environment
# without issuing anything or touching the VPN server. Costs no production rate
# limit, so run it as often as you like.
#
# It proves the parts that actually break: provider credentials, DNS propagation
# (or port 80 reachability), and the ACME round trip.

SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTPATH/common.sh"
set_colours

BASE=/opt/softether

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then
      echo "${RED}This script must be executed as root, Exiting... ${RESET}"
      exit 1
   fi

if [ ! -x "$BASE/scripts/certbot_renew.sh" ]; then
   echo "${RED}$BASE does not exist. Run install_softether.sh first. Exiting... ${RESET}"
   exit 1
fi

echo "Certbot Staging Dry Run" | banner

exec "$BASE/scripts/certbot_renew.sh" --dry-run
