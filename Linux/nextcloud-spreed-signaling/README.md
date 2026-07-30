## About

Spreed standalone signaling server for Nextcloud.

For more information please visit [https://github.com/strukturag/nextcloud-spreed-signaling](https://github.com/strukturag/nextcloud-spreed-signaling).

Original Credit and Inspiration: [MARKUS WEINGÄRTNER](https://markus-blog.de/index.php/2020/11/20/how-to-run-nextcloud-talk-high-performance-backend-with-stun-turnserver-on-ubuntu-with-docker-compose/)

## Contents

- [General Requirements](#general-requirements)
- [Prerequisites](#prerequisites)
- [Firewall Ports](#firewall-ports)
- [DNS](#dns)
- [Installation](#installation)
- [Let's Encrypt Certificates](#lets-encrypt-certificates)
- [Connect Nextcloud to Nextcloud-Signal](#connect-nextcloud-to-nextcloud-signal)
- [Upgrading](#upgrading)
- [Notes on media connectivity](#notes-on-media-connectivity)
- [Capacity and sizing](#capacity-and-sizing)
  - [UDP ports are usually the first limit](#udp-ports-are-usually-the-first-limit)
  - [Bandwidth](#bandwidth)
  - [CPU and memory](#cpu-and-memory)
  - [Measuring instead of estimating](#measuring-instead-of-estimating)
- [Troubleshooting](#troubleshooting)
  - [Calls work, but nothing reaches the signaling server](#calls-work-but-nothing-reaches-the-signaling-server)
  - [Is a call actually going through the stack?](#is-a-call-actually-going-through-the-stack)
  - [Watching a call in the logs](#watching-a-call-in-the-logs)
  - [Media telemetry is not available](#media-telemetry-is-not-available)
  - [Log messages that look alarming but are not](#log-messages-that-look-alarming-but-are-not)
  - [A 404 on the signaling URL is expected](#a-404-on-the-signaling-url-is-expected)

## General Requirements

Spreed standalone signaling server requires a fully updated Linux machine with the Docker engine and the **docker compose plugin** (not the legacy `docker-compose` binary) installed, as well as a fully functioning Nextcloud installation.

The installation script also needs `git`, `curl` and `openssl`. It uses them if they are already present, and otherwise installs them with whichever of `apt-get`, `dnf`, `yum`, `zypper`, `pacman` or `apk` is available. If none is found it tells you what to install and exits.


## Prerequisites

The installation script will prompt you for the following information. Ensure you have the following information available **BEFORE** running the script:

- **Nextcloud-Signal FQDN** The full name you wish to use for Nextcloud-Signal (Example: signal.domain.tld).
- **Nextcloud Instance URL** This is the FQDN URL of a Nextcloud server instance that will be connecting to the Nextcloud-Signal server. You **MUST** include http:// or https:// (Example: https://cloud.domain.tld). If you omit the scheme the script offers to add `https://` rather than accepting a value the signaling server cannot use.
- **Public IP address** The public IP address of this server. This is advertised to clients in ICE candidates and TURN relay addresses. The script offers the address the Nextcloud-Signal FQDN resolves to as the default, which on a host with several public addresses is the correct one by definition. If the server is behind 1:1 NAT, enter the public side of the NAT.
- **Bind IP address** (optional) If the server has multiple public IP addresses, the script can bind all published ports to a single one, so the stack does not claim ports on the others. The script verifies the address is actually configured on an interface before proceeding.

## Firewall Ports

The following ports must be open. The two UDP ranges are required for media to flow; without them calls connect and then drop.

| Port | Protocol | Purpose |
| --- | --- | --- |
| 80 | tcp | Let's Encrypt http-01 challenges, redirect to HTTPS |
| 443 | tcp | Signaling websocket and API |
| 3478 | tcp + udp | STUN / TURN |
| 5349 | tcp + udp | TURN over TLS (`turns:`) |
| 20000-20099 | udp | Janus media (RTP/RTCP) |
| 49160-49200 | udp | Coturn relay |

The UDP ranges are configurable in `/opt/nextcloud-spreed-signaling/.env` via `JANUS_RTP_MIN`/`JANUS_RTP_MAX` and `TURN_RELAY_MIN`/`TURN_RELAY_MAX`. Roughly one port is used per media stream, so ~100 ports covers a small deployment.

## DNS

The Nextcloud-Signal FQDN must resolve to this server before you run the installation, because the Let's Encrypt http-01 challenge connects to whatever DNS returns.

If you bound published ports to a specific IP (see **Bind IP address** above), the FQDN must resolve to **that exact address**. Ports listen only on the bound address, so if DNS points at any other IP on the host, nothing is listening and certificate issuance fails. Verify both before requesting a certificate:

```
dig +short signal.domain.tld
ss -lntp | grep ':80'
```

The address returned by `dig` and the address in the `ss` output must match.

## Installation

Clone the deeztek-docker repository with git:

```
sudo git clone https://github.com/deeztek/deeztek-docker.git
```

This will clone the repository and create a docker directory in the directory you ran the git clone command from.

Change to the nextcloud-spreed-signaling directory:

```
cd deeztek-docker/Linux/nextcloud-spreed-signaling
```

Run the following script as root:

```
sudo bash install_nextcloud_signal.sh
```

The script will create a **/opt/nextcloud-spreed-signaling/** directory and configure all necessary directories and files under that directory.

It will automatically generate the following random variables and insert those variables in the appropriate configuration files (server.conf, .env, default.conf):

* Static Secret
* Hash Key
* Block Key
* Shared Secret
* Api Key
* Internal Shared Secret

At the end of the run it prints the values needed to configure Nextcloud, along with the firewall ports to open. Take note of them:

* Static Secret (the TURN secret)
* Shared Secret (the high-performance backend secret)

It will build and deploy the following six containers:

* nextcloud_spreed_nginx
* nextcloud_spreed_backend
* nextcloud_spreed_janus
* nextcloud_spreed_coturn
* nextcloud_spreed_nats
* nextcloud_spreed_cron (ofelia, runs the certificate renewal job)

Only the Janus image is built from source; everything else uses a prebuilt, version-pinned image. The upstream repository is cloned to **/opt/nextcloud-spreed-signaling/** at the release tag matching the signaling server image, because the Janus 1.3.0 image is built from `docker/janus` in that repository and there is no published Janus 1.x image upstream.

## Let's Encrypt Certificates

The installation script automatically configures a scheduled cron job to renew Lets Encrypt Certificates on a daily basis.

By default, the script will launch Nginx reverse proxy with a self-signed certificate. If you wish to leverage a Lets Encrypt certificate, ensure that BOTH ports 80/TCP and 443/TCP are open to the Internet and that the **Nextcloud-Signal FQDN** you specified during installation points to the public IP of your Nextcloud-Signal instance.

Both certificate scripts read the Nextcloud-Signal FQDN from `/opt/nextcloud-spreed-signaling/.env` and ask you to confirm it, rather than having you retype it. They also warn if that name does not appear in the deployed nginx configuration, since a certificate issued under a name nginx is not serving would leave nginx unable to start.

Before attempting to get a production Lets Encrypt certificate, you should test with the Lets Encrypt Staging environment first by running the following script:

```
sudo bash certbot_certificate_staging.sh
```

The script asks you to agree to the Lets Encrypt Terms of Service and for an e-mail address for expiry notices, then runs certbot non-interactively. If it all goes well, it will output the following indicating success:

```
...
The dry run was successful.
...
```

If succesful, you can now safely run the following script to get a production Lets Encrypt Certificate:

```
sudo bash certbot_certificate_production.sh
```

The script asks you to agree to the Lets Encrypt Terms of Service and for an e-mail address for expiry notices, then runs certbot non-interactively. If it all goes well, it will output the following indicating success:

```
....
Successfully received certificate.
....
```

## Connect Nextcloud to Nextcloud-Signal

Login to Nextcloud as an Administrator and add and enable the **Nextcloud Talk** app. 

Next navigate to **Settings --> Administration --> Talk**. 

In the **STUN servers** section, enter the FQDN of your Nextcloud-Signal instance on port **3478** (Example: signal.domain.tld:3478).

In the **TURN servers** section, select **turns: only** on the drop-down and enter the FQDN of your Nextcloud-Signal instance on port **5349** (Example: signal.domain.tld:5349), then enter the **Static Secret** variable that was output earlier into the **secret** field.

> Use port **5349** for `turns:`, not 3478. Coturn's `--tls-listening-port` defaults to 5349; port 3478 is the plaintext STUN/TURN listener. Pointing a `turns:` URL at 3478 fails silently, and TURN then never works at all.

In the High-performance backend section, click the + button and enter **https://signal.domain.tld/standalone-signaling/** where **signal.domain.tld** is tha actual FQDN of your Nextcloud-Signal instance and in the **Shared secret** field enter the **Shared Secret** variable that was output ealier (**Figure 1**):

**Figure 1**

![Screenshot](2022_02_08_15_12_36.png)

## Upgrading

Run the upgrade script as root. It will prompt for the release to upgrade to (see the [upstream releases](https://github.com/strukturag/nextcloud-spreed-signaling/releases)):

```
sudo bash upgrade_nextcloud_signal.sh
```

The script stops the stack, checks out the requested release tag, updates the signaling server image tag in **docker-compose.yml**, rebuilds the Janus image, pulls the new images and brings everything back up. Your local `server.conf`, `.env`, `docker-compose.yml`, `nginx/`, `certbot/`, `coturn/`, `scripts/` and `ofelia/` are listed in `.git/info/exclude`, so the checkout leaves them alone. That file is deliberately used instead of `.gitignore`, which is tracked upstream: overwriting it would leave a permanently modified file and the checkout would abort whenever upstream changed it.

## Notes on media connectivity

Two settings in `.env` determine whether calls actually connect, and they are distinct:

- **`PUBLIC_IP`** is *advertised* to clients. Janus uses it for `--nat-1-1` and coturn for `--external-ip`. Without it, both advertise their container addresses (172.x.y.z), which no remote client can reach. Calls then either fail outright or connect and drop unpredictably.
- **`BIND_IP`** is the host address published ports *listen* on. This is optional: the installer asks whether you need it, and only writes it if you say yes. If you publish on all interfaces, the `${BIND_IP}:` prefix is stripped from every port mapping and the variable is removed from `.env`, so you get plain `"80:80"` mappings rather than an assumed `0.0.0.0:80:80`.

On a server with a directly attached public IP, `PUBLIC_IP` and `BIND_IP` are the same value. Behind 1:1 NAT, `PUBLIC_IP` is the public side and `BIND_IP` is the local interface.

To change the binding after installation, edit the `ports:` entries in `/opt/nextcloud-spreed-signaling/docker-compose.yml` and run `docker compose up -d`.

Do not point Janus at the local coturn with `--stun-server`. Coturn is on the same Docker network, so the STUN Binding response returns Janus's own container address; the resulting candidate is discarded and nothing is fixed.

## Capacity and sizing

Nextcloud publishes a baseline of **4 cores (must support AES), 8 GB RAM, 32 GB disk**, estimated at roughly **150 concurrent users**, and states that a call typically scales to **30-50 active participants** plus hundreds of passive ones, with capacity "limited primarily by bandwidth". See the [requirements](https://portal.nextcloud.com/article/Nextcloud-Talk/High-Performance-Backend/Requirements) and [scalability](https://nextcloud-talk.readthedocs.io/en/latest/scalability/) pages.

The figures below are arithmetic derived from how the stack works, not vendor numbers. They are worst case: real calls sit well under them because simulcast lowers the resolution of smaller tiles.

### UDP ports are usually the first limit

The signaling server creates one Janus subscriber per remote publisher, so an **N** participant call needs **N publisher connections plus N x (N-1) subscriber connections**, which is **N squared** peer connections in total. With BUNDLE and rtcp-mux each peer connection uses a single UDP port from the Janus range, and the range is shared across all concurrent calls.

| Participants in one call | Peer connections (UDP ports) | Worst case egress at 1 Mbps per stream |
| --- | --- | --- |
| 5 | 25 | 20 Mbps |
| 8 | 64 | 56 Mbps |
| 10 | 100 | 90 Mbps |
| 15 | 225 | 210 Mbps |
| 20 | 400 | 380 Mbps |
| 32 | 1024 | ~1 Gbps |

The default range in `.env` is `JANUS_RTP_MIN=20000` to `JANUS_RTP_MAX=20099`, which is **100 ports** and therefore about a 10 participant call, or several smaller concurrent ones totalling 100 connections. Widen it if you need more:

```
JANUS_RTP_MIN=20000
JANUS_RTP_MAX=20511
```

Then `docker compose up -d` and open the new range on the firewall. Both the `--rtp-port-range` flag and the published ports are derived from these two variables, so they cannot drift apart.

Avoid very large ranges. Docker creates one iptables rule per published port, which makes container startup slow. Beyond roughly 512 ports, `network_mode: host` for the Janus service is the better approach than publishing a thousand mappings.

The coturn relay range (`TURN_RELAY_MIN` to `TURN_RELAY_MAX`, 41 ports by default) limits concurrent **relayed** streams only. TURN is the fallback for clients that cannot reach Janus directly, so this is less pressing, and exhaustion shows up in the coturn logs first.

### Bandwidth

Egress is quadratic in participants: `N x (N-1) x stream bitrate`. Streams are capped at 1 Mbps and screenshares at 2 Mbps, reported at startup:

```
settings.go:70: Maximum bandwidth 1 Mbps per publishing stream
settings.go:78: Maximum bandwidth 2 Mbps per screensharing stream
```

Lowering `MAX_STREAM_BITRATE` is the highest leverage change if bandwidth becomes the constraint, because it scales the whole table linearly.

### CPU and memory

The SFU forwards packets and does not transcode, so load is mostly SRTP encryption and packet forwarding. This is why AES support is called out in the requirements: AES-NI makes a substantial difference. A modern core handles several hundred concurrent streams, so on a machine meeting the baseline the network link is reached long before the CPU.

Memory is modest. One caveat from upstream: if Janus event handlers are enabled and the consumer disconnects, unsent events queue inside Janus and can consume significant memory. Bound it with `events_cap_on_reconnect`. This does not apply unless event handlers are enabled, which they are not by default here.

### Measuring instead of estimating

```
docker exec nextcloud_spreed_backend wget -qO- http://127.0.0.1:8080/metrics \
  | grep -E 'publisher_streams|subscriber_streams|sessions|rooms'
```

The sum of `signaling_publisher_streams` and `signaling_subscriber_streams` is the live peer connection count, to compare against the size of the port range. Multiplying the subscriber count by the stream bitrate gives a worst case egress figure.

Upstream ships a benchmark client for load testing, though it notes that it "might not cover the whole functionality".

## Troubleshooting

### Calls work, but nothing reaches the signaling server

The symptom is that calls connect and behave normally while the stack sits completely idle: no sessions, nothing in the logs, Janus untouched. Nextcloud Talk falls back to its built-in peer-to-peer signaling whenever it decides not to use an external server, so calls keep working and nothing looks broken.

The first thing to check is what Nextcloud actually tells clients, which is **not** the same as what the admin interface displays. In a browser logged in to Nextcloud, open the developer console and run:

```
(await (await fetch('/ocs/v2.php/apps/spreed/api/v3/signaling/settings?format=json&_='+Date.now(),
  {headers:{'OCS-APIRequest':'true'},cache:'no-store'})).json()).ocs.data.signalingMode
```

`"external"` means clients are being sent here. `"internal"` means they are not, no matter what the admin page shows.

If it reports `internal` while a server is configured, check for a leftover mode override on the Nextcloud host:

```
occ config:app:get spreed signaling_mode
```

Any value there wins. Talk checks it **before** it looks at the configured servers and returns immediately if it is set to `internal`, so a correctly configured server is ignored and the admin page still reports the server as reachable. Delete it:

```
occ config:app:delete spreed signaling_mode
```

Then reload Talk. Note that no current version of Nextcloud Talk writes this value itself, it is only read and deleted, so it generally arrives through manual configuration, a setup script, or a leftover from the hosted signaling server offering. It is worth checking whenever clients ignore a server that is otherwise configured correctly.

### Is a call actually going through the stack?

```
docker exec nextcloud_spreed_backend wget -qO- http://127.0.0.1:8080/api/v1/stats
```

During a call `rooms` and `sessions` should be non-zero and `publishers` should match the number of participants sending media. `sessions` becomes non-zero as soon as Talk loads, so a call is not needed to test whether clients are connecting at all.

Richer counters are available on the metrics endpoint, which is restricted to localhost and so must also be run from inside the container:

```
docker exec nextcloud_spreed_backend wget -qO- http://127.0.0.1:8080/metrics \
  | grep -vE '^#|^go_|^process_|^promhttp_'
```

| Metric | Meaning |
| --- | --- |
| `signaling_sessions`, `signaling_rooms` | current sessions and conversations |
| `signaling_publisher_streams`, `signaling_subscriber_streams` | media streams currently established |
| `signaling_requests_errors_total` | backend request failures, should stay flat |
| `signaling_sessions_resume_failed_total` | clients failing to resume after a connection blip |

### Watching a call in the logs

```
docker compose logs -f --tail 0 spreedbackend | grep -E 'Register|Unregister|room|RTT'
docker compose logs -f --tail 0 janus | grep -iE 'Creating new handle|ICE|DTLS|WebRTC media is now available'
docker compose logs -f --tail 0 coturn | grep -E 'username=<[^>]'
```

`WebRTC media is now available` from Janus is the strongest single indicator: it means DTLS completed and media is flowing for that connection. Each participant connection adds a Janus handle beyond the one created at startup.

For coturn, **no output is the good result**. It means clients reached Janus directly using the public address from `--nat-1-1`. A non-empty `username=<timestamp:...>` means a client fell back to relaying, which works but sends all of that call's media through this server.

Use `--tail 0` or `--since`. Plain `docker compose logs -f` replays the entire buffer from container start, which buries current activity under startup output.

### Media telemetry is not available

The following metrics stay empty in this deployment: `selected_candidate_total`, `ice_state_total`, `dtls_state_total`, `media_bytes_total`, `media_rtt`, `media_jitter`, `media_lost_total`, `slow_link_total`.

They are populated from Janus events, and this setup does not enable the Janus websocket event handler. The signaling server reports this at startup:

```
Plugin janus.eventhandler.wsevh not found, realtime usage will not be available
```

Calls are unaffected. What is lost is per-stream quality telemetry, in particular `selected_candidate_total`, which would show whether calls connect directly or through the TURN relay. Enabling it requires mounting a custom `janus.jcfg` with the event handler configured.

### Log messages that look alarming but are not

| Message | Explanation |
| --- | --- |
| `ERROR: CONFIG: Empty cli-password ... telnet cli interface is disabled` | coturn reports this as an error, but a disabled admin telnet interface is the safe outcome |
| `Relay address to use: 172.x.x.x` | the address coturn binds to. `--external-ip` controls what is advertised to clients, not what is bound |
| coturn sessions with `username=<>` and `rb=20` | a 20 byte STUN Binding request from an internet scanner, not a call |
| `allocation watchdog determined stale session state` | coturn closing a session that never created a relay allocation, normal for the above |
| `No GRPC server certificate ... running unencrypted` | only relevant when clustering multiple signaling servers |
| nginx `active confs have different version dates than the samples` | the shipped `default.conf` differs from the image's sample, which is intended |
| `Could not upgrade request ... 'websocket' token not found` | a plain HTTP request to `/spreed`, typically a scanner or health check |

### A 404 on the signaling URL is expected

```
curl https://signal.domain.tld/standalone-signaling/     -> 404
```

The signaling server registers `/api/v1/welcome`, `/api/v1/room/{token}`, `/metrics`, `/turn/credentials` and `/spreed`. There is no route at `/`, so a 404 there indicates the proxy is working and reaching the backend. Test with the endpoint Nextcloud actually uses:

```
curl https://signal.domain.tld/standalone-signaling/api/v1/welcome
{"nextcloud-spreed-signaling":"Welcome","version":"..."}
```






