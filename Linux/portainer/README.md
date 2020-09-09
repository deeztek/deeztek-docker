**About**

Portainer simplifies container management in Docker, Swarm, Kubernetes, ACI and Edge environments. It's used by software engineers to speed up software deployments, troubleshoot problems and simplify migrations.

More information on Portainer can be found at the URL below:

[https://www.portainer.io/](https://www.portainer.io/)


**General Requirements**

Portainer requires that you have a fully updated Ubuntu 18.04 machine with Docker and Docker Compose and OpenSSL. The Docker host must have port 9000 available for use by portainer.

**Installation**

Portainer can be easily installed in your existing Ubuntu 18.04 based Docker host by utilizing either the **ubuntu_1804_install_portainer.sh** script.

**Quick script install and run instructions**

Git clone the Docker repository:

`sudo git clone https://github.com/deeztek/deeztek-docker.git`

This will clone the repository and create a deeztek-docker directory in the directory you ran the git clone command from.

Change to the portainer directory:

`cd deeztek-docker/Linux/portainer`

Run the following script as root:

`bash ubuntu_1804_install_portainer.sh`

The script will install all required components and install Portainer on the **/opt/portainer** directory of your Docker host

After installation the script will launch the Portainer container which in turn can be accessed by browsing to **https://IP_ADDRESS:9000** where **IP_ADDRESS** is the IP of your Docker host.






