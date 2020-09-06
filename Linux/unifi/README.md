**About**

Unifi Controller with Traefik support.

**Installation**

*  Git clone Repository

`https://gitlab.deeztek.com/dedwards/docker.git`

*  Adjust variables under **docker/Linux/unifi/.env** file

Set permissions for the **config** directory to the **PUID** and **GUID** from the .env file above (Usually 1001:1001):

`chown -R 1001:1001 config`

*  Start container

`docker-compose up -d`


**Unifi Backups**

The docker-compose.yml file has configuration to connect to a existing NFS share using the unifi_backups docker volume. 

Stop the matomo_mariadb container:

`docker container stop unifi`

Edit docker-compose.yml file and uncomment the following sections:

`#- unifi_backups:/unifi_backups`

```
#volumes:
  #unifi_backups:
    #driver_opts:
      #type: nfs
      #o: addr=192.168.30.200,nolock,soft,rw
      #device: :/mnt/backups
```

Set the **192.xxx.xxx.xxx** to the IP address of your NFS server and set **/mnt/backups** to the path of your NFS backups share

You will MOST likely have to setup the permissions on the **/mnt/backups** directory to the .env **PUID** as well in order for the script to have the permissions to create the backups to it as follows where **1001** is the **PUID** from the .env file from above:

`chown -R 1001:1001 /mnt/backups`

Edit **unifi/config/data/system.properties** file add the following line to it and save it:

`autobackup.dir=/unifi_backups`

Start the unifi container by using docker-compose:

`docker-compose up -d`




