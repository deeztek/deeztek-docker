SET vchost=192.168.xxx.xxx
SET vcport=2376
SET tlsverify=false
SET tlscert=c:\Users\dino.edwards\.docker\vch2\server-cert.pem
SET tlskey=c:\Users\dino.edwards\.docker\vch2\server-key.pem
SET tlscacert=c:\Users\dino.edwards\.docker\vch2\ca.pem

REM ==== Create Docker volume bw-data pointed to NFS volumestore freenas created previously (See https://gitlab.deeztek.com/dedwards/vic/blob/8c9b6b53263f20bf4292168e1b67e774cfb43fe4/scripts/vic_add_vch.bat)====

docker -H %vchost%:%vcport% --tlsverify=%tlsverify% --tlscert=%tlscert% --tlskey=%tlskey% --tlscacert=%tlscacert% volume create --opt volumestore=freenas bw-data