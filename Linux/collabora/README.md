## About

Collabora Online is a feature rich online collaboration office suite with great support for all major document, spreadsheet and presentation file formats. It is based on LibreOffice and used in combination with software for managing, sharing, files.

It can be installed on a server that you host yourself, or by a company of your choice. It is excellent for users and organizations looking for an office solution in the cloud that protects their privacy and allows them to keep full control of their sensitive data.

For more information please visit [https://www.collaboraoffice.com/code/](https://www.collaboraoffice.com/code/).

## General Requirements

Collabora requires that you have a fully updated Ubuntu 18.04 (also tested successfully on Ubuntu 20.04) machine with Docker and Docker Compose and an existing Traefik reverse proxy container installed and configured from [https://gitlab.deeztek.com/dedwards/docker/-/tree/master/Linux%2Ftraefik](https://gitlab.deeztek.com/dedwards/docker/-/tree/master/Linux%2Ftraefik).

## Traefik Special Configuration

Traefik must be configured to disable SSL certificate verification. This means that your certificate on Collabora can be the default self-signed one that comes with it.

You can safely use this configuration in production as long as the Collabora port is not exposed to the Internet and it's only accessed by Traefik internally.

Unfortunately, disabling SSL certificate verification is a global option in Traefik and it must be set in the Traefik **docker-compose.yml** file by adding the following line:

```
- "--serversTransport.insecureSkipVerify=true"
```

Save the file and restart the Traefik container by running the command below while in the Traefik directory, usually in **/opt/traefik**:

```
cd /opt/traefik && docker-compose down && docker-compose up -d
```

## Prerequisites

The installation script will prompt you for the following information. Ensure you have the following information available **BEFORE** running the script:

- **Site Name** This is the name the script will use to create custom directories, service names and Traefik labels (Example: mysite).
- **Collabora Hostname** This is the hostname you wish to use for Collabora **WITHOUT** the domain (Example: collabora). This is used in combination with the Collabora Domain to form the URL of your Collabora instance.
- **Collabora Domain** This is the domain you wish to use for Collabora (Example: domain.tld). This is used in combination with the Collabora Hostname to form the URL of your Collabora instance (Example: collabora.domain.tld).
- **Network name of your Traefik container** This is the name of the network of your Traefik container. This assume that Traefik is already configured and up and running. The script will attempt to list the Traefik container network for you.

## Installation

Clone the Docker repository with git:

```
sudo git clone https://github.com/deeztek/deeztek-docker.git
```

This will clone the repository and create a docker directory in the directory you ran the git clone command from.

Change to the collabora directory:

```
cd deezek-docker/Linux/collabora
```

Run the following script as root:

```
sudo bash ubuntu_install_collabora.sh
```

The script will create a **/opt/SITENAME-Collabora** directory where **SITENAME** is the Site Name you specify during installation, configure all necessary directories and files under that directory, generate a random username/password to be used to connect Nextcloud to Collabora and launch the Collabora stack. The random username/password that the script generates will be output by the script and it will also be set in the .env file in **/opt/SITENAME-Collabora**. 

## Let's Encrypt Certificates

By default, the script will leverage Traefik to generate a self-signed certificate for your Collabora container. By default, Let's Encrypt integration is not enabled. If you wish to enable Let's Encrypt automatic certificates, ensure your Collabora instance DNS is pointing to your Traefik container and edit **/opt/SITENAME-Collabora/docker-compose.yml**:

```
vi /opt/SITENAME-Collabora/docker-compose.yml
```

Uncomment the following Traefik label:

```
#- "traefik.http.routers.cloud-secure-SITENAME.tls.certresolver=le"
```

Restart the Collabora container (subsitute SITENAME with the actual name of the site your specified during installation):

```
cd /opt/SITENAME-Collabora && docker-compose down && docker-compose up -d
```

## Connect Nextcloud to Collabora

Login to Nextcloud as an Administrator and add and enable the **Collabora Online** app. 

Next navigate to **Settings --> Administration --> Office**. In the **Nextcloud Office** section, select **Use your own server**, in the **URL (andPort) of Collabora online-server** field, enter the following where **randomusername** and **randompassword** are the random Username/Password the script generated and **collabora.domain.tld** is the Collaboara Host and Domain you set during installation and click the **Save** button (**Figure 1**):

```
https://randomusername:randompassword@collabora.domain.tld
```

**Figure 1**

![Screenshot](2022_01_30_17_01_39.png)






