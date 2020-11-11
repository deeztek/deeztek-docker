#!/bin/bash

#Set Font Colors
RED=`tput setaf 1`
GREEN=`tput setaf 2`
RESET=`tput sgr0`

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

read -p "Enter a password you wish to use (Ensure you do NOT use $ , single or double quote special characters to form your password):"  THE_PASSWORD

if [ -z "$THE_PASSWORD" ]
then
      echo "${RED}The password cannot be empty ${RESET}"
      exit
fi

/usr/bin/docker run authelia/authelia authelia hash-password $THE_PASSWORD | sed 's/Password hash: //g'