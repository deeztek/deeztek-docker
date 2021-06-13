## About ##

Nextcloud is the first completely integrated on-premises content collaboration platform on the market, ready for a new generation of users who expect seamless online collaboration capabilities out of the box.

For more information please visit https://nextcloud.com

## General Requirements ##

Nextcloud requires that you have a fully updated Ubuntu 18.04 (also tested successfully on Ubuntu 20.04) machine with Docker and Docker Compose and an existing Traefik reverse proxy container installed and configured from [https://github.com/deeztek/deeztek-docker/tree/master/Linux/traefik]https://github.com/deeztek/deeztek-docker/tree/master/Linux/traefik).

## Nextcloud Docker Network Requirements ##

The Nextcloud Apache image will replace the remote addr (ip address visible to Nextcloud, not to be confused with the IP visible to Apache in the container logs) with the ip address from **X-Real-IP** if the request is coming from a proxy in the 10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16 IP range by default. Please see: [https://github.com/nextcloud/docker#using-the-apache-image-behind-a-reverse-proxy-and-auto-configure-server-host-and-protocol](https://github.com/nextcloud/docker#using-the-apache-image-behind-a-reverse-proxy-and-auto-configure-server-host-and-protocol)

So, it's important that your Traefik network address falls within the any of the following IP ranges:

```
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
```

The easiest way to accomplish this is by editing or creating the following file:

`vi /etc/docker/daemon.json`

and editing or adding the following (Example below utilizes the **172.16.0.0/12** network. Substitute with a range that suits your needs):

```
{
  "default-address-pools": [
    {
      "base": "172.16.0.0/12",
      "size": 24
    }
  ]
}
```

Save the file and restart your your docker service:

`systemctl restart docker`

If Traefik is running, you must remove it, delete the Traefik network and restart Traefik (If you used the Deeztek Traefik installation script, then the default Traefik network is usually named **proxy**. Obviously, adjust to your specific environment):

```
cd /opt/traefik
docker-compose down
docker network rm proxy
docker network create proxy
docker-compose up -d
```
## Prerequisites ##

The installation script will prompt you for the following information. Ensure you have the following information available **BEFORE** running the script:

- **Site Name** This is the name the script will use to create custom directories, service names and Traefik labels (Example: mysite).
- **MySQL/MariaDB Root Password** This is the MySQL/MariaDB root password. Ensure you do NOT use $ , single or double quote special characters to form your password or the script will fail.
- **MySQL/MariaDB Nextcloud Database Username** This is MySQL/MariaDB username for the Nextcloud Database (Example: nextcloud).
- **MySQL/MariaDB Nextcloud Database Password** This is the MySQL/MariaDB password for the Nextcloud Database Username. Ensure you do NOT use $ , single or double quote special characters to form your password or the script will fail.
- **MySQL/MariaDB Nextcloud Database Name** This is the MySQL/MariaDB database name you wish to use for Nextcloud (Example: nextclouddb)
- **Nextcloud Admin Username** This is the Nextcloud Admin Username you wish to use (Example: ncadmin).
- **Nextcloud Admin Password** This is the Nextcloud Admin password for the Nextcloud Admin Username. Ensure you do NOT use $ , single or double quote special characters to form your password or the script will fail.
- **Nextcloud Redis Password** This is the password you wish to use for Redis. Ensure you do NOT use $ , single or double quote special characters to form your password or the script will fail.
- **Nextcloud Hostname** This is the hostname you wish to use for Nextcloud **WITHOUT** the domain (Example: cloud). This is used in combination with the Nextcloud Subdomain to form the URL of your Nextcloud instance.
- **Nextcloud Subdomain** This is the subdomain you wish to use for Nextcloud (Example: domain.tld). This is used in combination with the Nextcloud Hostname to form the URL of your Nextcloud instance (Example: cloud.domain.tld).
- **Network name of your Traefik container** This is the name of the network of your Traefik container. This assume that Traefik is already configured and up and running. The script will attempt to list the Traefik container network for you.
- **IPv4 Subnet of your Traefik container network** This is the subnet of your Traefik container network. This will be used to configure the Trusted Proxies in Nextcloud. The script will attempt to list the IPv4 Subnet of you Traefik container network for you.
- **Nextcloud Data Path** This is the path the script will use to store all persistent Nextcloud data. The script will create all necessary directories under that path. Ensure the path already exists (Example: /mnt/data).

## Installation ##

Clone the Docker repository with git:

`sudo git clone https://github.com/deeztek/deeztek-docker.git`

This will clone the repository and create a docker directory in the directory you ran the git clone command from.

Change to the nextcloud directory:

`cd deeztek-docker/Linux/nextcloud`

Run the following script as root:

`bash ubuntu_1804_install_nextcloud.sh`

The script will create a **/opt/SITENAME-nextcloud** directory where **SITENAME** is the Site Name you specify during installation, configure all necessary directories and files under that directory and launch the nextcloud stack.

## Let's Encrypt Certificates ##

By default, the script will leverage Traefik to generate a self-signed certificate for your Nextcloud container. By default, Let's Encrypt integration is not enabled. If you wish to enable Let's Encrypt automatic certificates, ensure your Nextcloud instance DNS is pointing to your Traefik container and edit **/opt/SITENAME-nextcloud/docker-compose.yml**:

`vi /opt/SITENAME-nextcloud/docker-compose.yml`

Uncomment the following Traefik label:

`#- "traefik.http.routers.cloud-secure-SITENAME.tls.certresolver=le"`

Restart the Nextcoud container.

## Database Backups ##

The installation script will automatically configure database backups and place a **dbbackups.sh** script along with any database backups in the **db_backups** directory under the Nextcloud Data path you specified during installation.

If you wish to have e-mail notifications of backup successes/failures, edit **/opt/SITENAME-nextcloud/ofelia_config/config.ini**:

`vi /opt/SITENAME-nextcloud/ofelia_config/config.ini`

Set the parameters below under the [global] section to reflect your e-mail server:

```
[global]
smtp-host = smtp.domain.tld
smtp-port = 465
smtp-user = someone@domain.tld
smtp-password = somepassword
email-to = someone@domain.tld
email-from = someone@domain.tld
mail-only-on-error = false
```

By default the job is scheduled to run at 1:30 AM as indicated by the entry below in **/opt/SITENAME-nextcloud/ofelia_config/config.ini**. Adjust as required:

```
[job-exec "run-nextcloud-backups"]
schedule = 0 30 1 * * *
container = SITENAME_nextcloud_db
command = /db_backups/dbbackups.sh
```

Restart the nextcloud_db_cron container:

`docker container restart SITENAME_nextcloud_db_cron`

Restart the nextcloud_db container:

`docker container restart SITENAME_nextcloud_db`




