**About**

Softether VPN Server with Traefik support and automated Lets Encrypt Certificate Import. The docker-compose.yml file utilizes siomiz/softethervpn, ldez/traefik-certs-dumper and mcuadros/ofelia containers.

**Installation**


*  Git clone Repository

`https://gitlab.deeztek.com/dedwards/docker.git`


*  Adjust variables under **docker/Linux/softether/.env** file (Mainly Timezone (**TZ**) and domain (**DOMAIN**) variables


*  Adjust **/path/to/trafeik/acme.json** in **docker/Linux/softether/docker-compose.yml** file under the **certs --> Volumes** service and ensure it points to your existing **acme.json** file
*  Edit **docker/Linux/softether/ofelia_config/config.ini** and replace `<softetheradminpassword>` field with your Softether VPN server Administration Console password
*  Start containers

`docker-compose up -d`

*  Ensure certificates are generated under **docker/Linux/softether/certs** directory

As new certificates are issued by Let's Encrypt they SHOULD automatically show up under **docker/Linux/softether/certs** provided that your Let's Encrypt config is correct
