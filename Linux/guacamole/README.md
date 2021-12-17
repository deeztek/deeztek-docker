**About**

Apache Guacamole is a clientless remote desktop gateway. It supports standard protocols like VNC, RDP, and SSH.

It's called clientless because no plugins or client software are required.

Thanks to HTML5, once Guacamole is installed on a server, all you need to access your desktops is a web browser.

More information on Apache Guacamole can be found at the URL below:

[https://guacamole.apache.org/](https://guacamole.apache.org/)


**General Requirements**

Apache Guacamole requires that you have a fully updated Ubuntu 18.04 machine with Docker and Docker Compose and an existing Traefik reverse proxy container installed and configured from [https://github.com/deeztek/deeztek-docker/tree/master/Linux/traefik](https://github.com/deeztek/deeztek-docker/tree/master/Linux/traefik).

**Guacamole with Local User Authentication Requirements**

You must have a valid external host and domain that's configured to point to your Guacamole container via a reverse proxy (Example: guacamole.domain.tld).

**Guacamole with LDAP User Authentication Requirements**

You must have a valid external host and domain that's configured to point to your Guacamole container via a reverse proxy (Example: guacamole.domain.tld).

You must have a working LDAP or Active Directory environment.

You must have a user with permissions to enumerate users for use with Guacamole already added in your LDAP/Active Directory environment.

During installation, you will be asked to provide the LDAP Host Name or IP.

During installation, you will be asked to provide the LDAP Host Port (Example: "389" or "636").

During installation, you will be asked to provide the LDAP Host Encryption. You must provide "none" for unsecure or "ssl" or "starttls" for secure.

During installation, you will be asked to provide the Gucamole user you added Distinguished Name (Example: CN=ldap_user,CN=Users,DC=domain,DC=tld).

During installation, you will be asked to provide the Gucamole user you added password.

During installation, you will be asked to provide the LDAP Users that will be logging into Guacamole Distinguished Name (Example: CN=Users,DC=domain,DC=tld).

**Installation**

Guacamole can be easily installed in your existing Ubuntu 18.04 based Docker host by utilizing either the **ubuntu_1804_install_guacamole.sh** script for use with local user authentication or by utilizing the **ubuntu_1804_install_guacamole_ldap.sh** script for LDAP user authentication.

**Quick script install and run instructions**

Git clone the Docker repository:

`sudo git clone https://github.com/deeztek/deeztek-docker.git`

This will clone the repository and create a deeztek-docker directory in the directory you ran the git clone command from.

Change to the guacamole directory:

`cd deeztek-docker/Linux/guacamole`

For local user authentication run the following script as root:

`sudo bash ubuntu_1804_install_guacamole.sh`

For LDAP user authentication run the following script as root:

`sudo bash ubuntu_1804_install_guacamole_ldap.sh`

The script will install all required components and install Guacamole on the **/opt/guacamole** directory of your Docker host

After installation the script will launch the Guacamole container which in turn can be accessed by browsing to **https://HOSTNAME.DOMAIN** where **HOSTNAME** is the Guacamole hostname you specified and the **DOMAIN** is the subdomain you specified when you were prompted by the install scripts.

The default credentials for the Guacamole Web GUI is:

Username: guacadmin
Password: guacadmin

The **/opt/guacamole/.env** file has all the configuration variables that you set when you were prompted when running any of the scripts. 

**Duo MFA Requirements**

* Register for a Free Duo account at: https://duo.com/
* Create a new “Auth API” application by browing to **Dashboard > Applications > Protect an Application > Web SDK**
* Scroll down, under **Settings** and change the name to “Guacamole,” or something of your choice.
* Note following information:

```
Integration Key
Secret Key
API hostname
```

**Duo MFA Automated Configuration**

During Guacamole installation by either the **ubuntu_1804_install_guacamole.sh** or the **ubuntu_1804_install_guacamole_ldap.sh** scripts, you will be prompted to enable Duo MFA support. If you answer yes, you will be prompted for **Intergration Key**, **Secret Key** and the **API Hostname** that you obtained from the Duo website (See **Duo MFA Requirements** section above) and the script will automatically configure Duo MFA support for your Guacamole container.

**Duo MFA Manual Configuration**

If you wish to manually configure Duo MFA support, follow the instructions below:

* Generate a duo “application key” on your docker host using the command below:  

`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1`

* Note the resultant generated key.

* Edit **/opt/guacamole/docker-compose.yml** file and uncomment the following line:

`#      GUACAMOLE_HOME: /guacamole_home`

* Edit **/opt/guacamole/guacamole_home/guacamole.properties** file and set the following parameters (See **Duo MFA Requirements** section above):

```
duo-api-hostname: duo_api_hostname_from_above
duo-integration-key: duo_integration_key_from_above
duo-secret-key: duo_secret_key_from_above
duo-application-key: duo_application_key_from_above
#Uncomment below if you wish to be able to skip Duo 2FA if it's unavailable
#skip-if-unavailable: duo 
```
* Save and restart Guacamole container. 




