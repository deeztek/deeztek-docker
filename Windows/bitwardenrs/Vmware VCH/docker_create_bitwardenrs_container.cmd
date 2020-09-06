SET vchost=192.168.xxx.xxx
SET vcport=2376
SET tlsverify=false
SET tlscert=c:\Users\dino.edwards\.docker\vch2\server-cert.pem
SET tlskey=c:\Users\dino.edwards\.docker\vch2\server-key.pem
SET tlscacert=c:\Users\dino.edwards\.docker\vch2\ca.pem

REM ==== Create bitwardenrs container setting DATA_FOLDER variable to the bw-data volume created previously (See https://gitlab.deeztek.com/dedwards/docker/blob/591d4eeb160db2bcc8fc3a5ca260ca9eca44fe4d/bitwardenrs/docker_create_nfs_volume_bitwardenrs.cmd) and setting persistent storage to it (persistent storage appears to the left of the colon (:) i.e. bw-data: )====

docker -H %vchost%:%vcport% --tlsverify=%tlsverify% --tlscert=%tlscert% --tlskey=%tlskey% --tlscacert=%tlscacert% run -d --name bitwarden -e DATA_FOLDER=/bw-data -v bw-data:/bw-data/ -p 9080:80 bitwardenrs/server:latest