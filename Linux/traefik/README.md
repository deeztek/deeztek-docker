**About**

Traefik is an open-source Edge Router that makes publishing your services a fun and easy experience. It receives requests on behalf of your system and finds out which components are responsible for handling them.

What sets Traefik apart, besides its many features, is that it automatically discovers the right configuration for your services. The magic happens when Traefik inspects your infrastructure, where it finds relevant information and discovers which service serves which request.

Traefik is natively compliant with every major cluster technology, such as Kubernetes, Docker, Docker Swarm, AWS, Mesos, Marathon, and the list goes on; and can handle many at the same time. (It even works for legacy software running on bare metal.)

With Traefik, there is no need to maintain and synchronize a separate configuration file: everything happens automatically, in real time (no restarts, no connection interruptions). With Traefik, you spend time developing and deploying new features to your system, not on configuring and maintaining its working state.

More information on Traefik can be found at the URL below:

[https://docs.traefik.io/](https://docs.traefik.io/)


**Requirements**

Traefik requires that both **TCP/80** and **TCP/443** are available in your Docker host.

**Installation**

Traefik can be easily installed in your existing Ubuntu 18.04 based Docker host by utilizing the **ubuntu_1804_install_traefik.sh** script.

**Quick script install and run instructions**

Git clone the Docker repository:

`sudo git clone https://github.com/deeztek/deeztek-docker.git`

This will clone the repository and create a docker directory in the directory you ran the git clone command from.

Change to the traefik directory:

`cd docker/Linux/traefik`

Run the following script as root:

`bash ubuntu_1804_install_traefik.sh`

The script will install all required components and install Traefik on the **/opt/traefik** directory of your Docker host

**Configuration**

The Traefik dashboard can be accessed by browsing to **https://HOSTNAME.DOMAIN** where **HOSTNAME** is the Traefik hostname you specified and the **DOMAIN** is the subdomain you specified when you were prompted by the **ubuntu_1804_install_traefik.sh** install script.

By default the Traefik installation is set to use the Let's Encrypt Staging servers to obtain certificates through the use of the following line in the **/opt/traefik/docker-compose.yml** file:

`- "--certificatesResolvers.le.acme.caServer=https://acme-staging-v02.api.letsencrypt.org/directory"`

Once a staging certificate has been successfully issued, comment out the line above to use the production Let's Encrypt servers.

Additionally, the Traefik installation is by default set to use ACME httpChallenge method to obtain certificates through the use of the following line in the **/opt/traefik/docker-compose.yml** file:

`- "--certificatesResolvers.le.acme.httpChallenge.entryPoint=http"`

If you wish to use ACME dnschallenge or ACME TLS challenge, comment out the ACME httpChallenge line from above and uncomment the appropriate lines(s) in the **/opt/traefik/docker-compose.yml** file. The **/opt/traefik/docker-compose.yml** file is extensively commented with instructions on how to implement the various ACME methods.




