#!/bin/bash

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then
      echo "==== ERROR ===="  | boxes -d stone -p a2v1
      echo "This script must be executed as root, Exiting..."
      exit 1
   fi

# Linux Docker Bash Menu

while true
do
PS3='Please Select Option: '
options=("Install Docker and Docker Compose" "Install Portainer" "Install Traefik" "Install Guacamole with Local User Authentication" "Install Guacamole with LDAP User Authentication" "Exit")
select opt in "${options[@]}"
do
    case $opt in
        "Install Docker and Docker Compose")
            cd docker/ && bash ubuntu_1804_install_docker_compose.sh
            break
            ;;
        "Install Portainer")
            cd portainer/ && bash ubuntu_1804_install_portainer.sh
            break
            ;;
        "Install Traefik")
            cd traefik/ && bash ubuntu_1804_install_traefik.sh
            break
            ;;
         "Install Guacamole with Local User Authentication")
            cd guacamole/ && bash ubuntu_1804_install_guacamole.sh
            break
            ;;
        "Install Guacamole with LDAP User Authentication")
            cd guacamole/ && bash ubuntu_1804_install_guacamole_ldap.sh
            break
            ;;
    
        
        "Exit")
            echo "Exiting...."
            exit
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
done
