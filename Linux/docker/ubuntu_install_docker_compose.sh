#!/bin/bash

#This script will install Docker and Docker Compose on your Ubuntu machine. Ensure your Ubuntu installation has all the latest updates.

#With your favorite browser, visit https://github.com/docker/compose/releases/latest and get the version number of the latest Docker Componse release (Example 1.25.1). 

#Make this script executable:
#chmod +x ubuntu_1804_docker_compose.sh

#Run the script as root:
#./ubuntu_1804_docker_compose.sh OR bash ubuntu_1804_docker_compose.sh

#Enter the username of the user you would like to be able to run Docker commands without having to prefix with sudo when prompted.

#Enter the Docker Compose version you obtained earlier when prompted.

#Install boxes
apt install -y boxes

#Get Inputs
read -p "Enter the username of the user you would like to run Docker commands without having to prefix with sudo:"  THEUSER

#Prompt no longer needed. We get latest version automatically below with curl and sed
#read -p "Browse to https://github.com/docker/compose/releases/latest to get the latest Docker version and then enter that Docker version in order to install. Ensure you include the 'v' in the version number (Example v2.1.0):"  DOCKERCOMPOSEVERSION

#Ensure Script is run as root and if not exit
if [ `id -u` -ne 0 ]; then
      echo "This script must be executed as root, Exiting..."
      exit 1
   fi


#Get latest Docker Compose URL
DOCKERCOMPOSEURL=`curl $1 -s -L -I -o /dev/null -w '%{url_effective}' https://github.com/docker/compose/releases/latest`

#Grep latest Docker Compose version from $THEURL
DOCKERCOMPOSEVERSION=`echo "$DOCKERCOMPOSEURL" | sed 's:.*/::'`

#Get Ubuntu Release Code Name in order to add correct Docker Repository
UBUNTUCODENAME=`. /etc/os-release; echo ${UBUNTU_CODENAME/*, /}`

echo "Starting Docker Compose $DOCKERCOMPOSEVERSION Installation" | boxes -d stone -p a2v1

echo "[`date +%m/%d/%Y-%H:%M`] Installing prerequisites" 

#Install Prerequisites
apt install -y apt-transport-https ca-certificates curl software-properties-common curl nfs-common

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred during installing prerequisites"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed installing prerequisites"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Adding GPG Key for Official Docker Repository"

#Add GPG Key for official Docker Repository:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred adding GPG Key for Official Docker Repository"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed adding GPG Key for Official Docker Repository"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Adding Docker repository to APT Sources"

#Add Docker repository to APT sources
add-apt-repository -y  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $UBUNTUCODENAME stable"

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred adding Docker repository to APT Sources"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed adding Docker repository to APT Sources"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Updating Sources"

#Update Sources
apt update

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred updating sources"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed updating sources"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Installing Docker"

#Install Docker
apt install -y docker-ce

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, occurred installing Docker"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed installing Docker"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Adding $THEUSER user to docker group"

#Add user to docker group
/usr/sbin/usermod -aG docker $THEUSER

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, adding $THEUSER user to docker group"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed adding $THEUSER user to docker group"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Downloading Docker Compose version $DOCKERCOMPOSEVERSION"

#Generate docker-compose download filename since they changed it from docker-compose-Linux-amd64 to docker-compose-linux-amd64
FILENAME=docker-compose-`uname -s`-`uname -m`
FILENAMESMALL=${FILENAME,,}

#Download Docker Compose Version Specified above
curl -L https://github.com/docker/compose/releases/download/$DOCKERCOMPOSEVERSION/$FILENAMESMALL -o /usr/local/bin/docker-compose

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, downloading Docker Compose version $DOCKERCOMPOSEVERSION"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed downloading Docker Compose version $DOCKERCOMPOSEVERSION"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Making Docker Compose Executable"

#Make docker-compose executable
chmod +x /usr/local/bin/docker-compose

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, making Docker Compose Executable"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed making Docker Compose Executable"
fi

echo "[`date +%m/%d/%Y-%H:%M`] Downloading and Installing Docker Compose Switch"

#Download and install Docker Compose Switch
#curl -fL https://raw.githubusercontent.com/docker/compose-cli/main/scripts/install/install_linux.sh | sh

#ERR=$?
#if [ $ERR != 0 ]; then
#THEERROR=$(($THEERROR+$ERR))
#echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, downloading and installing Docker Compose Switch"
#exit 1
#else
#echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed downloading and installing Docker Compose Switch"
#fi

echo "[`date +%m/%d/%Y-%H:%M`] Printing out Docker Compose Version"

#Verify succesfull installation by printing out version
docker-compose --version

ERR=$?
if [ $ERR != 0 ]; then
THEERROR=$(($THEERROR+$ERR))
echo "[`date +%m/%d/%Y-%H:%M`] ERROR: $ERR, printing out Docker Compose Version"
exit 1
else
echo "[`date +%m/%d/%Y-%H:%M`] SUCCESS. Completed printing out Docker Compose Version"
echo "The version output above should be docker-compose version $DOCKERCOMPOSEVERSION. If not, installation has failed"
fi


