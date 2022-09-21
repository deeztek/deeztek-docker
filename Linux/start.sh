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
options=("Install Docker and Docker Compose" "Install Portainer" "Install Traefik" "Install Guacamole with Local User Authentication" "Install Guacamole with LDAP User Authentication" "Install Zabbix" "Install Nextcloud" "Install OnlyOffice" "Exit")
select opt in "${options[@]}"
do
    case $opt in
        "Install Docker and Docker Compose")
            cd docker/ && bash ubuntu_1804_install_docker_compose.sh
            cd -
            break
            ;;
        "Install Portainer")
            cd portainer/ && bash ubuntu_1804_install_portainer.sh
            cd -
            break
            ;;
        "Install Traefik")
            cd traefik/ && bash ubuntu_1804_install_traefik.sh
            cd -
            break
            ;;
         "Install Guacamole with Local User Authentication")
            cd guacamole/ && bash ubuntu_1804_install_guacamole.sh
            cd -
            break
            ;;
        "Install Guacamole with LDAP User Authentication")
            cd guacamole/ && bash ubuntu_1804_install_guacamole_ldap.sh
            cd -
            break
            ;;

        "Install Zabbix")
            cd zabbix/ && bash ubuntu_install_zabbix.sh
            cd -
            break
            ;;
    
        "Install Nextcloud")
            cd nextcloud/ && bash ubuntu_1804_install_nextcloud.sh
            cd -
            break
            ;;

        "Install OnlyOffice")
            cd onlyoffice/ && bash ubuntu_1804_install_onlyoffice.sh
            cd -
            break
            ;;

    "Install Collabora")
            cd collabora/ && bash ubuntu_install_collabora.sh
            cd -
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
