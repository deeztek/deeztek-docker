#!/bin/bash

#CHECK IF MOUNT EXISTS
if mount | grep -q "/db_backups"; then

#Enter MySQL/MariaDB root credentials below
USER="mysql_root_user"
PASSWORD="mysql_root_password"

#Enter MySQL/MariaDB dbserver name below
DBSERVER="dbserver"

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
