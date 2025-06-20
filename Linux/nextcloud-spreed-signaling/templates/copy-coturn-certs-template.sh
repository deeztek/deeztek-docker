#!/bin/bash

#Copy certificate and private key to coturn
cp /opt/nextcloud-spreed-signaling/certbot/conf/live/SIGNALHOSTNAME.SIGNALDOMAIN/fullchain.pem /opt/nextcloud-spreed-signaling/coturn/fullchain.pem
cp /opt/nextcloud-spreed-signaling/certbot/conf/live/SIGNALHOSTNAME.SIGNALDOMAIN/privkey.pem /opt/nextcloud-spreed-signaling/coturn/privkey.pem

#Set certificate and key permissions
chmod 0644 -R /opt/nextcloud-spreed-signaling/coturn/

#Restart Coturn container to load new certificate and key
docker container restart nextcloud_spreed_coturn