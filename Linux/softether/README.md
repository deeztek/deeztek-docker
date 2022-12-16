**About**

Softether VPN Server with Traefik support and automated Lets Encrypt Certificate Import. The docker-compose.yml file utilizes siomiz/softethervpn, ldez/traefik-certs-dumper and mcuadros/ofelia containers.

**Installation**


*  Git clone Repository

`https://gitlab.deeztek.com/dedwards/docker.git`


*  Adjust variables under **docker/Linux/softether/.env** file: Timezone (**TZ**), host (**HOST**), domain (**DOMAIN**), Server Managemennt Password (**SPW**), Hub Management Password (**HPW**) and the IPSec/L2TP Pre-Shared Key (**PSK**).


*  Adjust **/path/to/trafeik/acme.json** in **docker/Linux/softether/docker-compose.yml** file under the **certs --> Volumes** service and ensure it points to your existing **acme.json** file
*  Uncomment and edit **docker/Linux/softether/ofelia_config/config.ini** and replace `<softetheradminpassword>` field with your Softether VPN server Administration Console password
*  Start containers

`docker-compose up -d`

*  Ensure certificates are generated under **docker/Linux/softether/certs** directory

As new certificates are issued by Let's Encrypt they SHOULD automatically show up under **docker/Linux/softether/certs** provided that your Let's Encrypt config is correct

**Server Management**

By default ALL IPs are denied administration access to Softether by virtue of the existing adminips.txt file under the /opt/softether/softether_config/vpnserver directory. Add IPs you wish to be allowed to administer the server and/or Softether Hub in that file (each in its own line), install the Softether Server Manager tools on the a machine with an allowed IP and connect to the Softether server. More information on adminips.txt can be found at: https://www.softether.org/4-docs/1-manual/3._SoftEther_VPN_Server_Manual/3.3_VPN_Server_Administration#3.3.18_Restricting_by_IP_Address_of_Remote_Administration_Connection_Source_IPs

