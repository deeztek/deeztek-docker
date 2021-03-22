**About**

Wordpress with Traefik support.

**Installation**

*  Git clone Repository

`https://github.com/deeztek/deeztek-docker.git`

*  Adjust variables under **docker/Linux/wordpress/.env** file

Set permissions for the **db_data** directory to the **PUID** and **GUID** from the .env file above (Usually 1001:1001) or MySQL will not start:

`chown -R 1001:1001 db_data`

*  Start container

`docker-compose up -d`

**Wordpress MySQL Database Backups**

The docker-compose.yml file includes the **wordpress_db_cron**  container that is based on the **mcuadros/ofelia:latest** image which can be used to schedule database backups of the Wordpress MySQL database. The docker-compose.yml file also has configuration to optionally connect to a existing NFS or CIFS/SMB share using the db_backups docker volume. 

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




