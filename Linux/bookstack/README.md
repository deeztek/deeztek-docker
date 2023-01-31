**About**

BookStack is a simple, self-hosted, easy-to-use platform for organising and storing information.

For more information please visit https://www.bookstackapp.com

**General Requirements**

Bookstack requires that you have a fully updated Ubuntu 18.04+ machine with Docker and Docker Compose and an existing Traefik reverse proxy container installed and configured from [https://github.com/deeztek/deeztek-docker/tree/master/Linux/traefik](https://github.com/deeztek/deeztek-docker/tree/master/Linux/traefik).

**Installation**

Clone the Deeztek Docker repository with git:

`sudo git clone https://github.com/deeztek/deeztek-docker.git`

This will clone the repository and create a docker directory in the directory you ran the git clone command from.

Copy the bookstack directory to /opt (or a directory of your choice):

`cp -r deeztek-docker/Linux/bookstack /opt/`

Edit the .env file:

`vi /opt/bookstack/.env`

Change the following variables to suit your needs, ensuring you set the DBPASS and the MYSQLROOTPASS fields:

```
TZ=America/New_York
HOST=host
DOMAIN=domain.tld
DBDATABASE=bookstackapp
DBUSER=bookstack
DBPASS=bookstack_mysql_password
MYSQLROOTUSER=root
MYSQLROOTPASS=mysql_root_password
```

Bring up the bookstack container:

`docker-compose up -d`

Navigate to the bookstack URL at https://[HOST].[DOMAIN] where [HOST] AND [DOMAIN] are the host and domain values you set in the .env file above. Login with the the following default credentials:

Username: admin@admin.com
Password: password

Change the default credentials immediately after login.

**Database Backups**

Edit /opt/bookstack/db_backups/dbbackups.sh file:

`vi /opt/bookstack/db_backups/dbbackups.sh`

Set the PASSWORD="mysql_root_password" to match the MYSQLROOTPASS from the .env file from above.

Save the file

Make it executable:

`chmod +x /mnt/backups/dbbackups.sh`

If you wish to have e-mail notifications of backup successes/failures, edit /opt/bookstack/ofelia_config/config.ini:

`vi /opt/bookstack/ofelia_config/config.ini`

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

By default the job is scheduled to run at 1:30 AM as indicated by the entry below in /opt/bookstack/ofelia_config/config.ini. Adjust as required:

```
[job-exec "run-bookstack-backups"]
schedule = 0 30 1 * * *
container = bookstack_db
command = /db_backups/dbbackups.sh
```

Restart the bookstack_mariadb_cron container:

`docker container restart bookstack_mariadb_cron`

Restart the bookstack_db container:

`docker container restart bookstack_db`




