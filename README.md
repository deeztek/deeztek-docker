## About

A collection of scripts and Docker Compose stacks to ease the installation of Docker, Docker Compose and various containers on your Ubuntu host.

## General Requirements

A fully updated **Ubuntu LTS** machine. The installation scripts are developed against the current LTS releases (22.04 and 24.04) and install Docker from Docker's official Ubuntu repository.

`Linux/docker/ubuntu_install_docker_compose.sh` refuses to run on anything other than Ubuntu, because it configures Docker's Ubuntu apt repository. For other distributions, install Docker using [Docker's own instructions](https://docs.docker.com/engine/install/) and then use the Compose stacks in this repository directly.

Everything installs **Docker Compose v2** as the `docker compose` plugin. The legacy `docker-compose` v1 binary is not used and is removed if present.

## Quick script install and run instructions

Clone the repository:

```
sudo git clone https://github.com/deeztek/deeztek-docker.git
```

This creates a `deeztek-docker` directory in the directory you ran the clone from.

Change to the Linux directory:

```
cd deeztek-docker/Linux/
```

Run the menu as root:

```
sudo bash start.sh
```

## What the menu installs

`start.sh` is a convenience wrapper around a subset of the directories here. It currently offers:

| Menu entry | Runs |
| --- | --- |
| Install Docker and Docker Compose | `docker/ubuntu_install_docker_compose.sh` |
| Install Portainer | `portainer/ubuntu_1804_install_portainer.sh` |
| Install Traefik | `traefik/ubuntu_1804_install_traefik.sh` |
| Install Guacamole with Local User Authentication | `guacamole/ubuntu_1804_install_guacamole.sh` |
| Install Guacamole with LDAP User Authentication | `guacamole/ubuntu_1804_install_guacamole_ldap.sh` |
| Install Zabbix Server | `zabbix/ubuntu_install_zabbix.sh` |
| Install Nextcloud | `nextcloud/ubuntu_1804_install_nextcloud.sh` |
| Install OnlyOffice | `onlyoffice/ubuntu_1804_install_onlyoffice.sh` |
| Install Collabora | `collabora/ubuntu_install_collabora.sh` |
| Install Wordpress | `wordpress/ubuntu_install_wordpress.sh` |
| Install Softether VPN | `softether/install_softether.sh` |
| Install Nextcloud Talk Signaling Server | `nextcloud-spreed-signaling/install_nextcloud_signal.sh` |

Install Docker first if the host does not already have it.

## Work in progress

`Linux/authentik` is **incomplete and not currently working**. It contains an installation script and templates, but the script is unfinished and its `README.md` is still a copy of the Zabbix one. Do not run it. It is left in the repository as work in progress rather than as something to deploy.

## Everything else

The remaining directories under `Linux/` are Docker Compose stacks rather than guided installers. Each has its own `README.md` with setup instructions, and is deployed by editing the provided `.env` and `docker-compose.yml` and running `docker compose up -d`.

Currently: airsonic, authelia, bitwardenrs, bookstack, commandbox, coturn, deluge, discourse, gitlab, graylog, haproxy, haproxy-le, heimdall, jackett, librarian, lidarr, mailtrain, mariadb, matomo, openemr, openldap, organizr, prestashop, pureftpd, radarr, sabnzbd, sftpgo, sonarr, unifi, vaultwarden, watchtower.

Read the directory's `README.md` before deploying. Several ship placeholder credentials that must be changed.
