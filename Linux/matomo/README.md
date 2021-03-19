**About**

Matomo Analytics with Traefik support.

**Installation**

*  Git clone Repository

`https://gitlab.deeztek.com/dedwards/docker.git`

*  Adjust variables under **docker/Linux/matomo/.env** file

Set permissions for the **mariadb_data** directory to the **PUID** and **GUID** from the .env file above (Usually 1001:1001) or MariaDB will not start:

`chown -R 1001:1001 mariadb_data`

*  Start container

`docker-compose up -d`

After container is launched and **matomo_data/matomo/config/config.ini.php** is created, stop the container:

`docker container stop matomo`

Edit **matomo_data/matomo/config/config.ini.php** and add the following under the **[General]** section like below:

```
[General]
...
; Uncomment line below if you use a standard proxy
proxy_client_headers[] = HTTP_X_FORWARDED_FOR
...
```
**Start container**

`docker container start matomo`

**Matomo MariaDB Database Backups**

The docker-compose.yml file includes the **mcuadros/ofelia:latest** container which can be used to schedule database backups of the matomo MariaDB database. The docker-compose.yml file also has configuration to connect to a existing NFS share using the db_backups docker volume. 

Stop the matomo_mariadb container:

`docker container stop matomo_mariadb`

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
      #device: "//192.168.xxx.xxx/shares/backups/matomo"
```

and set the **192.xxx.xxx.xxx** to the IP address of your CIFS/SMB server, set **/backups/matomo** to the CIFS/SMB share, set **smbuser** to the CIFS/SMB username, set **smbpass** to the CIFS/SMB password and set **SMBDOMAIN** to the domain/workgroup you are connecting.

Edit the included dbbackups.sh file and set the following parameters:

USER="mysql_root_user"

PASSWORD="mysql_root_password"

DBSERVER="dbserver"

where **mysql_root_user** is the mariadb root user (usually root), **mysql_root_password** is the password for the mariadb root user and **dbserver** is directory you wish to store the database backups. You will MOST likely have to setup the permissions on the **dbserver** directory to the 1001 UID as well in order for the script to have the permissions to dump the database backups to it as follows:

`chown -R 1001 /mnt/dbbackups/dbserver`

where **/mnt/dbbackups/dbserver** is the path to your NFS share.

Save dbbackups.sh file and make it executable:

`chmod +x dbbackups.sh`

Copy **dbbackups.sh** to the root of db_backups NFS share

Edit **ofelia_config/config.ini** file and ensure the **schedule** parameter is acceptable (Default is every day at 1:00 A.M.) and ensure the **container** parameter is set to the correct container name (Default matomo_mariadb should be fine unless you changed the name of the container in the docker-compose.yml file)

Start the matomo_mariadb container by using docker-compose:

`docker-compose up -d`




