SET vchost=192.168.XXX.XXX
SET vcport=2376
SET tlsverify=false
SET tlscert=c:\Users\dino.edwards\.docker\vchhdg1\server-cert.pem
SET tlskey=c:\Users\dino.edwards\.docker\vchhdg1\server-key.pem
SET tlscacert=c:\Users\dino.edwards\.docker\ca.pem

docker -H %vchost%:%vcport% --tlsverify=%tlsverify% --tlscert=%tlscert% --tlskey=%tlskey% --tlscacert=%tlscacert% run -d --name bitwarden -e ROCKET_TLS={certs=/ssl/certs.pem,key=/ssl/key.pem} -e DATA_FOLDER=/bw-data -v bw-data:/bw-data/ -v ssl:/ssl/ -p 443:80 -e DATABASE_URL="mysql://MYSQL_USERNAME:MYSQL_PASSWORD@MYSQL_SERVER/MYSQL_BITWARDEN_DATABASE" -e ENABLE_DB_WAL='false' bitwardenrs/server-mysql:latest

