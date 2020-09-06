**Configuring coturn**

Generate Secret

`openssl rand -hex 32`

Enter generated secret from above to config/turnserver.conf

`static-auth-secret=your_generated_secret`

Adjust the realm to your domain in config/turnserver.conf

`realm=domain.tld`

Ensure TCP port 3478 is accessible from your firewall to the Docker Host IP

