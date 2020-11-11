**About**

Zabbix is an enterprise-class open source distributed monitoring solution.

Zabbix is software that monitors numerous parameters of a network and the health and integrity of servers. Zabbix uses a flexible notification mechanism that allows users to configure e-mail based alerts for virtually any event. This allows a fast reaction to server problems. Zabbix offers excellent reporting and data visualisation features based on the stored data. This makes Zabbix ideal for capacity planning.

For more information and related downloads for Zabbix components, please visit https://hub.docker.com/u/zabbix/ and https://zabbix.com

**General Requirements**

Zabbix requires that you have a fully updated Ubuntu 18.04 machine with Docker and Docker Compose and an existing Traefik reverse proxy container installed and configured from [https://gitlab.deeztek.com/dedwards/docker/-/tree/master/Linux%2Ftraefik](https://gitlab.deeztek.com/dedwards/docker/-/tree/master/Linux%2Ftraefik).

**Installation**

Clone the Deeztek Docker repository with git:

`sudo git clone https://gitlab.deeztek.com/dedwards/docker.git`

This will clone the repository and create a docker directory in the directory you ran the git clone command from.

Change to the zabbix directory:

`cd docker/Linux/zabbix`

Run the following script as root:

`bash ubuntu_1804_install_zabbix.sh`

**Backups**

Create /mnt/backups in your Docker Host:

`mkdir /mnt/backups`

Copy docker/Linux/zabbix/backups/.smbcreds to a directory of your choice (In the example below we copy to the /home/myuser directory):

`cp docker/Linux/zabbix/backups/.smbcreds /home/myuser`

Edit /home/myuser/.smbcreds:

`vi /home/myuser/.smbcreds`

Change smb_username, smb_password and smb_domain to match your environment:

```
username=smb_username
password=smb_password
domain=smb_domain
```


Save the file

Copy the following entry in docker/Linux/zabbix/etc/fstab file and paste in your /etc/fstab file and change 192.168.xxx.xxx to the IP of your SMB host, zabbix_backups to your SMB share and /home/myuser/.smbcreds:

```
#MOUNT ZABBIX BACKUPS
//192.168.xxx.xxx/zabbix_backups /mnt/backups cifs file_mode=0777,dir_mode=0777,credentials=/home/myuser/.smbcreds
```


Ensure you cifs-utils are installed on the docker host:

`sudo apt install cifs-utils`

Mount the /mnt/backups share:

`mount /mnt/backups`

Ensure it's mounted succesfully

Copy docker/Linux/zabbix/backups/dbbackups.sh to /mnt/backups

`cp docker/Linux/zabbix/backups/dbbackups.sh to /mnt/backups`

Edit /mnt/backups/dbbackups.sh:

`vi /mnt/backups/dbbackups.sh`

Change the root_password in the entry below to reflect the MySQL root password that you set during Zabbix installation:

`PASSWORD="root_password"`

Save the file

Make it executable:

`chmod +x /mnt/backups/dbbackups.sh`

If you wish to have e-mail notifications of backup successes/failures, edit /opt/zabbix-docker/ofelia_config/config.ini:

`vi /opt/zabbix-docker/ofelia_config/config.ini`

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

By default the job is scheduled to run at 1:30 AM as indicated by the entry below in /opt/zabbix-docker-ofelia_config/config.ini. Adjust as required:

```
[job-exec "run-database-backups"]
schedule = 0 30 1 * * *
container = zabbix-docker_mysql-server_1
command = /db_backups/dbbackups.sh
```


Restart the zabbix_cron container:

`docker container restart zabbix_cron`

Restart the zabbix-docker-mysql-server_1 container:

`docker container restart zabbix-docker_mysql-server_1`




