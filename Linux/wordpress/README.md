**About**

Wordpress with Ofelia for Cron, Redis Cache and Traefik Proxy support.

**Prerequites**

The script requires that you have a fully updated Ubuntu server (tested on Ubuntu 18.04 LTS, 20.04 LTS and 22.04 LTS) and functional Traefik Proxy. A Traefik Proxy can easily be deployed by utilizing our automated Traefik install script under deeztek-docker/Linux/traefik directory or by utilizing the start.sh script under deeztek-docker/Linux directory after you git clone this repository.

**Required Information**

The install script will prompt you for the following information before it starts installation. Ensure you have that information available before you begin:

* A unique Wordpress site name you wish you use with no spaces or special characters (Example: mywordpresssite)
* A Wordpress database name you wish you use with no spaces or special characters (Example: mywordpresssite_db)
* The PRIMARY ROOT domain for your Wordpress site INCLUDING www. in front if applicable (Example: www.domain.tld OR host.domain.tld)
* Any additional domain for your Wordpress site if applicable (Example: domain.tld)
* An EXISTING data path WITHOUT an ending slash "/" for your Wordpress site, database and redis data (Example: /mnt/data)

**Installation**

*  Git clone Repository

`https://github.com/deeztek/deeztek-docker.git`

This will clone the repository and create a **deeztek-docker** directory in the directory you ran the git clone command from.

Change to the deeztek-docker/Linux/wordpress directory:

`cd deeztek-docker/Linux/wordpress/`

Make script executable:

`sudo chmod +x ubuntu_install_wordpress.sh`

Run the script as root:

`sudo ./ubuntu_install_wordpress.sh`

The script will prompt you for the information outlined in the **Required Information** section, it will create a directory structure under /opt/Wordpress-SITENAME, create a data directory structure under the data path you provided, it will automatically generate random MySQL/MariaDB root password, MySQL/MariaDB Wordpress Database username, MySQL/MariaDB Wordpress Database password, Redis password, configure the appropriate configuration files as well as the docker-compose.yml file and start the docker stack. The randomly generated strings for MySQL/MariaDB and Redis will be stored in the .env file in the /opt/Wordpress-SITENAME directory as well as the install_log-xxxxxxxx.log that will be generated in the deeztek-docker/Linux/wordpress directory. 

**If you require support for and you wish to post the install_log-xxxxxxxx.log file to assist with troubleshooting, ensure you anonymize the randomly generated strings in that file beforehand.**

**Redis Cache**

After your Wordpress site is up and running it's highly recommended you install and configure the [Redis Object Cache](https://wordpress.org/plugins/redis-cache/) plugin in order to take advantage of the Redis container that gets deployed with this stack. Redis will offer substantial performance improvement for your website.

**Wordpress MySQL Database Backups**

The docker-compose.yml file includes the **wordpress_cron_SITENAME** container (where SITENAME is the site name you entered when prompted by the install script) that is based on the **mcuadros/ofelia:latest** image which by default runs every 5 minutes for various Wordpress related scheduled jobs. Additionally, it can be used to schedule database backups of the Wordpress MySQL database. The docker-compose.yml file also has configuration to optionally connect to a existing NFS or CIFS/SMB share using the db_backups docker volume. 

Stop the wordpress_db container:

`docker container stop wordpress_db`

Edit docker-compose.yml file and uncomment the following section:

`#- db_backups:/db_backups`

If you are going to be backing up to an existing NFS share uncomment the section below:

```
#volumes:
  #db_backups:
    #driver: local
    #driver_opts:
      #type: nfs
      #o: addr=192.xxx.xxx.xxx,nolock,soft,rw
      #device: :/mnt/dbbackups
```

and set the **192.xxx.xxx.xxx** to the IP address of your NFS server and set **/mnt/dbbackups** to the path of your NFS backups share.

If you are going to be backing up to an existing CIFS/SMB share uncomment the section below:

```
#db_backups:
    #driver_opts:
      #type: cifs
      #o: vers=3.02,mfsymlinks,username=smbuser,password=smbpass,domain=SMBDOMAIN,file_mode=0777,dir_mode=0777,iocharset=utf8
      #device: "//192.168.xxx.xxx/shares/backups/wordpress"
```

and set the **192.xxx.xxx.xxx** to the IP address of your CIFS/SMB server, set **/backups/wordpress** to the CIFS/SMB share, set **smbuser** to the CIFS/SMB username, set **smbpass** to the CIFS/SMB password and set **SMBDOMAIN** to the domain/workgroup you are connecting.

Edit the included dbbackups.sh file and set the following parameters:

USER="mysql_root_user"

PASSWORD="mysql_root_password"

DBSERVER="dbserver"

where **mysql_root_user** is the MySQL root user (usually root), **mysql_root_password** is the password for the MySQL root user and **dbserver** is directory you wish to store the database backups. You will MOST likely have to setup the permissions on the **dbserver** directory to the 1001 UID as well in order for the script to have the permissions to dump the database backups to it as follows:

`chown -R 1001 db_backups`

where **db_backups** is the path to your backups share.

Save dbbackups.sh file and make it executable:

`chmod +x dbbackups.sh`

Copy **dbbackups.sh** to the root of db_backups share

Edit **ofelia_config/config.ini** file and ensure the **schedule** parameter is acceptable (Default is every day at 1:30 A.M.) and ensure the **container** parameter is set to the correct container name (Default db should be fine unless you changed the name of the container in the docker-compose.yml file). Additionally set the [global] section parameters to your e-mail settings if you wish to receive backup notifications.

Start the wordpress_db container by using docker-compose:

`docker-compose up -d`




