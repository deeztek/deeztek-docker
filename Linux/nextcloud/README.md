**About**

Nextcloud is the first completely integrated on-premises content collaboration platform on the market, ready for a new generation of users who expect seamless online collaboration capabilities out of the box.

For more information please visit https://nextcloud.com

**General Requirements**

Nextcloud requires that you have a fully updated Ubuntu 18.04 machine with Docker and Docker Compose and an existing Traefik reverse proxy container installed and configured from [https://gitlab.deeztek.com/dedwards/docker/-/tree/master/Linux%2Ftraefik](https://gitlab.deeztek.com/dedwards/docker/-/tree/master/Linux%2Ftraefik).

**Nextcloud Docker Network Requirements**

The Nextcloud Apache image will replace the remote addr (ip address visible to Nextcloud) with the ip address from **X-Real-IP** if the request is coming from a proxy in the 10.0.0.0/8, 172.16.0.0/12 or 192.168.0.0/16 IP range by default. Please see: [https://github.com/nextcloud/docker#using-the-apache-image-behind-a-reverse-proxy-and-auto-configure-server-host-and-protocol](https://github.com/nextcloud/docker#using-the-apache-image-behind-a-reverse-proxy-and-auto-configure-server-host-and-protocol)

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
docker-compose up -d
```

**Note**

The provided docker-compose.yml will install smbclient and vim in the nextcloud container using the included **Dockerfile** in order to provide SMB/CIFS support for Nextcloud.

**Installation**

Clone the Deeztek Docker repository with git:

`sudo git clone https://github.com/deeztek/deeztek-docker.git`

This will clone the repository and create a docker directory in the directory you ran the git clone command from.

Copy the nextcloud directory to /opt (or a directory of your choice):

`cp -r deeztek-docker/Linux/nextcloud /opt/`

Edit the .env file:

`vi /opt/nextcloud/.env`

Change the following variables to suit your needs:

```
TIMEZONE=America/New_York
PUID=1001
GUID=1001
NEXTCLOUD_ADMIN_USER=nextcloud_admin_user	
NEXTCLOUD_ADMIN_PASSWORD=netxtcloud_admin_password
NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.domain.tld
TRUSTED_PROXIES=172.16.0.0/16
REDIS_PASSWORD=redis_password
SMTP_HOST=smtp.domain.tld
#Set below to ssl for SSL or tls for STARTTLS or leave it empty for non-secure
SMTP_SECURE=STARTTLS
#Set below for 465 for ssl or 587 for STARTTLS or 25 for non-secure
SMTP_PORT=587
#Set below for LOGIN for authentication or PLAIN for no authentication
SMTP_AUTHTYPE=PLAIN
SMTP_NAME=smtp_username
SMTP_PASSWORD=smtp_password
MAIL_FROM_ADDRESS=someone@domain.tld
MAIL_DOMAIN=domain.tld
HOST=nextcloud
DOMAIN=domain.tld

```

Edit the db.env file:

`vi /opt/nextcloud/db.env`

Change the following variables to suit your needs:

```
MYSQL_ROOT_PASSWORD=mysql_root_password
MYSQL_USER=nextcloud
MYSQL_PASSWORD=mysql_password
MYSQL_DATABASE=nextcloud
```

Bring up the nextcloud containers:

`docker-compose up -d`

**Database Backups**

Edit /opt/nextcloud/db_backups/dbbackups.sh file:

`vi /opt/nextcloud/db_backups/dbbackups.sh`

Set the PASSWORD="mysql_root_password" to match the MYSQLROOTPASS from the db.env file from above.

Save the file

Make it executable:

`chmod +x /mnt/backups/dbbackups.sh`

If you wish to have e-mail notifications of backup successes/failures, edit /opt/nextcloud/ofelia_config/config.ini:

`vi /opt/nextcloud/ofelia_config/config.ini`

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

By default the job is scheduled to run at 1:30 AM as indicated by the entry below in /opt/nextcloud/ofelia_config/config.ini. Adjust as required:

```
[job-exec "run-nextcloud-backups"]
schedule = 0 30 1 * * *
container = nextcloud_db
command = /db_backups/dbbackups.sh
```

Restart the nextcloud_db_cron container:

`docker container restart nextcloud_db_cron`

Restart the nextcloud_db container:

`docker container restart nextcloud_db`




