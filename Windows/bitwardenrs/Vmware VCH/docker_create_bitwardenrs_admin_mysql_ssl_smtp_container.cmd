SET vchost=192.168.XXX.XXX
SET vcport=2376
SET tlsverify=false
SET tlscert=c:\Users\dino.edwards\.docker\vchhdg1\server-cert.pem
SET tlskey=c:\Users\dino.edwards\.docker\vchhdg1\server-key.pem
SET tlscacert=c:\Users\dino.edwards\.docker\ca.pem

docker -H %vchost%:%vcport% --tlsverify=%tlsverify% --tlscert=%tlscert% --tlskey=%tlskey% --tlscacert=%tlscacert% run -d --name bitwarden -e ROCKET_TLS={certs=/ssl/certs.pem,key=/ssl/key.pem} -e DATA_FOLDER=/bw-data -v bw-data:/bw-data/ -v ssl:/ssl/ -p 443:80 -e DATABASE_URL="mysql://MYSQL_USER:MYSQL_PASSWORD@MYSQL_SERVER/BITWARDEN_DATABASE" -e ENABLE_DB_WAL='false' -e ADMIN_TOKEN="LONG_RANDOMLY_GENERATED_STRING_OF_CHARACTERS" -e SMTP_HOST=SMTP.DOMAIN.TLD -e SMTP_FROM=SOMEONE@DOMAIN.TLD -e SMTP_PORT=587 -e SMTP_PORT=587 -e SMTP_SSL=true -e SMTP_USERNAME=SMTP_USERNAME -e SMTP_PASSWORD="SMTP_PASSWORD" -e SIGNUPS_ALLOWED=false bitwardenrs/server-mysql:latest

