#Create bitwarden_rs container with data folder defined as bw-data pointing to existing NFS mount, admin interface, smtp server, mysql backend to existing mysql server, no user signups allowed, domain defined in order to enable U2F authentication. No SSL has been configured as this relies on a separate Nginx reverse proxy for encryption 

#==== DO NOT USE ANY SPECIAL CHARACTERS FOR PASSWORDS ====

docker run -d --name bitwarden \
-e DATABASE_URL='mysql://mysql_username:mysql_password@mysql_server/mysql_database' \
-e DATA_FOLDER=/bw-data \
-e ENABLE_DB_WAL='false' \
-e ADMIN_TOKEN='long_randomly_generated_string_of_characters' \
-e SMTP_HOST=smtp.domain.tld \
-e SMTP_FROM='My Bitwarden' \
-e SMTP_PORT=587 \
-e SMTP_SSL=true \
-e SMTP_USERNAME=smtp_username \
-e SMTP_PASSWORD='smtp_password' \
-e SIGNUPS_ALLOWED='false' \
-e DOMAIN=bitwarden.domain.tld \
-v /mnt/bw-data:/bw-data/ \
-p 80:80 \
bitwardenrs/server-mysql:latest