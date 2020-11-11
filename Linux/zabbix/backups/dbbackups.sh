#!/bin/bash

#ENSURE THIS FILE IS UNIX FORMAT BY RUNNING THE FOLLOWING COMMAND
#dos2unix dbbackups.sh

#CHECK IF MOUNT EXISTS
if mount | grep -q "/db_backups"; then

#Enter MySQL/MariaDB root credentials below
USER="root"
PASSWORD="root_password"

#Enter MySQL/MariaDB dbserver name below
DBSERVER="dbzabbix"

#Check if /db_backups/$DBSERVER exists and if not create it
if [ ! -d "/db_backups/$DBSERVER" ]; then
      mkdir -p /db_backups/$DBSERVER
      echo "/db_backups/$DBSERVER directory does not exist. Creating...."
   fi

#Check if /db_backups/$DBSERVER exists and if not exit
if [ ! -d "/db_backups/$DBSERVER" ]; then
      echo "The /db_backups/$DBSERVER directory does not exist even after attempting to create automatically. Exiting for now..."
      exit 1
   fi


databases=`mysql -u $USER -p$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

for db in $databases; do
    if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] ; then
        echo "Dumping database: $db"
        mysqldump -u $USER -p$PASSWORD --opt --databases $db>/db_backups/$DBSERVER/`date +%m-%d-%Y-%H%M`-$db.sql
       # gzip $OUTPUT/`date +%Y%m%d`.$db.sql

fi

done

#Dump Users
echo "Dumping database: mysql user table"
mysqldump -u $USER -p$PASSWORD mysql user>/db_backups/$DBSERVER/`date +%m-%d-%Y-%H%M`-user_table.sql

#Delete backup files older than 30 days
/usr/bin/find /db_backups/$DBSERVER/*.sql -mtime +30 -exec rm {} \;


fi

