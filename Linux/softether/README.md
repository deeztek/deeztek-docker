# SoftEther VPN

SoftEther VPN Server with automatic Let's Encrypt certificate renewal, scheduled
by Ofelia. Installs to `/opt/softether`.

Ofelia runs certbot nightly; when — and only when — a certificate is actually
renewed, it is installed into SoftEther with `vpncmd` and the server is
restarted.

`install_softether.sh` asks for everything: platform, FQDN, ACME email,
validation method (dns-01 or http-01), DNS provider and that provider's specific
credentials, staging vs production, and the SoftEther admin password.

```text
ofelia ──(nightly 03:17, docker API)──▶ docker:cli container
                                          │ runs scripts/certbot_renew.sh
                                          ▼
                                       certbot container (ad-hoc, exits when done)
                                          │ --deploy-hook touches a marker
                                          ▼ only if the marker appeared
                                       vpncmd ServerCertSet  (load fullchain+key)
                                       vpncmd Flush          (persist to disk)
                                       docker restart        (vpnserver)
```

## Deploying

### Before you start

- **Docker** with the Compose plugin (`docker compose version` must work).
- **A DNS record.** For dns-01 the zone must be hosted at the provider whose API
  credentials you are about to enter. For http-01 the FQDN's A record must point
  at this host, and TCP/80 must be free and reachable from the internet.
- **Ports.** 443, 992, 5555 TCP and 500, 4500, 1194 UDP must be free.

### Install

```bash
git clone https://github.com/deeztek/deeztek-docker.git
cd deeztek-docker/Linux/softether
sudo bash install_softether.sh
```

Or run it from the menu: `sudo bash Linux/start.sh` → **Install SoftEther VPN**.

The script must be run as root. It installs everything under **`/opt/softether`**
and writes a timestamped `install_log-<date>.log` next to itself.

It prompts for the platform (auto-detected, overridable), FQDN, ACME email,
validation method, DNS provider and its credentials, staging vs production, and
the SoftEther administration password. Then it creates `/opt/softether`, starts
SoftEther, reconciles the admin password, **runs a staging dry run and refuses to
issue a real certificate if that fails**, issues, and starts the scheduler.

Re-run it any time to change an answer; it is idempotent and offers the previous
answers from `/opt/softether/.env` as defaults.

### Installed layout

```text
/opt/softether/
├── docker-compose.yml           from templates/
├── .env                         generated, mode 600
├── ofelia/config.ini            generated (absolute paths substituted in)
├── scripts/certbot_renew.sh     from templates/
├── secrets/                     credentials, mode 600
├── certbot/{conf,lib,logs}/     certbot state
└── softether_config/{data,logs}/   vpn_server.config lives in data/
```

Everything is a bind mount under `/opt/softether`, at the **same absolute path**
on the host and inside every container. That is what lets ofelia and the renew
script share paths with no translation, and it is why `ofelia/config.ini` is
generated rather than copied — ofelia talks to the Docker API directly and
cannot resolve relative paths.

## Why the install is not just "copy the file and restart"

SoftEther does **not** read a PEM off disk at boot. The server certificate lives
inside `vpn_server.config`, so it has to be pushed in with `vpncmd ServerCertSet`.

And `ServerCertSet` alone is not enough. It only mutates SoftEther's **in-memory**
config. That reaches disk in exactly two ways: a 300-second timer
(`uint AutoSaveConfigSpan 300`, present in `vpn_server.config`), or a clean
shutdown.

A container restart is never a clean shutdown. `vpnserver execsvc` runs as PID 1
and installs no SIGTERM handler, so `docker stop`/`docker restart` waits out the
whole grace period and then SIGKILLs it — exit code 137, nothing written. Raising
`stop_grace_period` does not help; it only makes restarts slower. So without an
explicit `vpncmd Flush` the restart *discards the new certificate* and the server
comes back on the old one. Silently: `ServerCertSet` still reports
`The command completed successfully`.

All of that was measured, not assumed:

| Sequence | On-disk config afterwards |
| --- | --- |
| `ServerCertSet`, then `docker restart` | unchanged — new cert lost |
| change, then `docker stop --timeout 30` | unchanged — took the full 30s, exit 137 |
| change, then `vpncmd Flush` | updated |

Without `Flush` the served certificate was unchanged after the restart, and the
admin password set in the same session was lost too. With `Flush`, the served
fingerprint matched the new certificate exactly.

The same rule applies to *any* `vpncmd` change — hubs, users, listeners. Flush
before restarting, or wait out the five minutes.

## Validation methods

| Requirement | dns-01 | http-01 |
| --- | --- | --- |
| Needs inbound TCP/80 | no | **yes** |
| Works behind NAT | yes | no |
| Needs DNS API credentials | yes | no |
| Wildcard certificates | yes | no |

**dns-01 is the recommended choice here** and is the first option in the
installer. A VPN server has no web server, and dns-01 needs neither an open port
80 nor a publicly reachable address.

### How http-01 works without a web server

There isn't one — certbot *is* the web server. `--standalone` makes the ad-hoc
certbot container bind port 80 itself, serve the file under
`/.well-known/acme-challenge/` for the few seconds Let's Encrypt takes to fetch
it, then exit. `-p 80:80` publishes it only for that window; nothing listens on
80 the rest of the time. SoftEther's own listeners are 443, 992, 1194 and 5555,
so there is no clash.

> **⚠ http-01 is NOT tested end to end.**
>
> Verifying a real http-01 challenge needs a public domain pointing at the test
> host, which was not available. What *was* verified: the `standalone` plugin is
> present in the certbot image, certbot's argument list is built correctly for
> it, and port 80 is free in this stack. What was **not** verified: an actual
> successful http-01 issuance.
>
> dns-01 *is* verified end to end. If you need http-01 and it misbehaves, treat
> it as unproven code rather than a configuration mistake on your side.

Two http-01 failure modes that dns-01 does not have, both of which surface at
renewal time (3am) rather than at install:

- **Port 80 must be free at that moment.** If anything has claimed it since
  install, `docker run -p 80:80` fails and so does the renewal.
- **Port 80 must be reachable from the internet** — firewall, NAT forward, and
  no ISP block on inbound 80.

If you run http-01, `certbot_test.sh` is worth running on a schedule of its own:
it exercises the real port-80 path against staging at no rate-limit cost.

### Supported DNS providers

All thirteen official certbot DNS plugins, each verified to publish an arm64
image. `install_softether.sh` knows the exact credential fields for each, taken from the
plugins' own source rather than from documentation:

`cloudflare` · `digitalocean` · `dnsimple` · `dnsmadeeasy` · `gehirn` · `google` ·
`linode` · `luadns` · `nsone` · `ovh` · `rfc2136` · `route53` · `sakuracloud`

Most write a `secrets/<provider>.ini`. Three are special and are handled for you:
Cloudflare offers scoped-token or legacy global-key auth, Google takes a service
account JSON file, and Route 53 uses `AWS_*` environment variables rather than a
credentials file.

## Testing

```bash
sudo bash certbot_test.sh        # staging dry run: no rate limit cost, changes nothing
```

This exercises the parts that actually break — provider credentials, DNS
propagation (or port 80 reachability), and the ACME round trip — without issuing
anything or touching the VPN server. Run it as often as you like.

```bash
/opt/softether/scripts/certbot_renew.sh            # what ofelia runs nightly
/opt/softether/scripts/certbot_renew.sh --force    # renew even if not due (costs rate limit)
docker logs softether-ofelia            # scheduler history
```

Confirm what clients actually get:

```bash
echo | openssl s_client -connect "$VPN_DOMAIN:443" -servername "$VPN_DOMAIN" 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates
```

### Moving from staging to production

Re-run `install_softether.sh` and pick production. Certbot will not move a lineage
between ACME servers on its own, so `certbot_renew.sh` compares the stored
`server` in `/opt/softether/certbot/conf/renewal/<domain>.conf` against `.env` and forces a
reissue when they differ.

## Migrating an existing SoftEther server

**The admin password lives inside `vpn_server.config`**, as `byte HashedPassword`
under `ServerConfiguration`. It is a plain hash, so it travels with the file —
copy your config in and the server keeps its existing password. You only have to
tell the tooling what it is.

```bash
sudo mkdir -p /opt/softether/softether_config/data
sudo cp /path/to/your/vpn_server.config /opt/softether/softether_config/data/
sudo chmod 600 /opt/softether/softether_config/data/vpn_server.config
sudo bash install_softether.sh    # enter the EXISTING admin password when prompted
```

`install_softether.sh` probes the password before changing anything, so it is a no-op when
it already matches. To change it, pass the old one once:

```bash
SE_CURRENT_PASSWORD='old-password' sudo -E bash install_softether.sh
```

Two things to check after copying a config in:

- **Ports.** Your config's `ListenerList` must line up with the `ports:` block in
  `docker-compose.yml`.
- **Existing certificate.** Your config arrives with its old `ServerCert`. If you
  also bring over an existing `certbot/conf`, certbot will find the cert still
  valid, skip renewal, and therefore not install anything — the old certificate
  keeps being served. Use `/opt/softether/scripts/certbot_renew.sh --force`.

### A note on `vpncmd` and wrong passwords

If the admin password is wrong, `vpncmd` does not exit with an error — it prints
`Access has been denied` and then blocks forever on an interactive `Password:`
prompt, **even with stdin closed**. Every `vpncmd` call here is wrapped in
`timeout` and turns that into a clear error. Without the wrapper it would wedge
the nightly job indefinitely.

## Layout

This directory holds the installer and its templates; nothing here is the
running stack. See [Installed layout](#installed-layout) for what ends up in
`/opt/softether`.

```text
install_softether.sh                       interactive installer; re-runnable
certbot_test.sh                            staging dry run against the install
common.sh, spinner.sh                      shared repo helpers
lib/providers.sh                           per-provider credential fields and hints
templates/softether-docker-compose-template.yml
templates/certbot_renew-template           obtain/renew + install into SoftEther
templates/config.ini-template              ofelia schedule; __BASE__ substituted
```

Files under `/opt/softether/softether_config/` and `/opt/softether/certbot/` are
created by containers running as root, so removing them needs `sudo`.

## Notes

- **Schedule.** `templates/config.ini-template`, `schedule = 0 17 3 * * *` →
  03:17 nightly. Ofelia's cron parser takes an optional leading seconds field, so
  5- and 6-field specs both work, as do `@daily` / `@every 24h`. Edit the
  template and re-run `install_softether.sh`. Nightly is intentionally boring: certbot only
  acts inside the last 30 days, so this renews about once every 60 days.
- **Platform.** `install_softether.sh` detects the host architecture and writes
  `TARGET_PLATFORM` to `/opt/softether/.env`; compose interpolates it. Override it there to run
  a different architecture.
- **No certbot service in compose.** The certbot container is created ad-hoc by
  the renew script and exits when done, so nothing idles.
- **Local bridging.** Ports are published on a bridge network, which covers
  SecureNAT / SSL-VPN / L2TP / OpenVPN. For a SoftEther *local bridge* onto a
  physical NIC, switch `vpnserver` to `network_mode: host` and drop `ports:`.
- **Docker socket.** Ofelia and the renew job mount `/var/run/docker.sock`, which
  is root-equivalent on the host. That is what lets the job restart SoftEther.

## Verification status

Verified on an x86_64 test host:

- arm64 manifests exist for `softethervpn/vpnserver:5.2`, `mcuadros/ofelia`,
  `docker:cli`, `certbot/certbot` and **all 13** `certbot/dns-*` plugin images.
- Certbot argument construction is correct for dns-01 (ini, JSON and env-var
  provider styles), http-01, first issuance, renew, `--force`, `--dry-run`, and
  the staging→production switch.
- `install_softether.sh` end to end: prompts, credential file written correctly at mode
  600, `.env` and `ofelia/config.ini` generated, SoftEther started, admin
  password set and flushed, staging dry run reached Let's Encrypt and correctly
  aborted before issuing.
- Full renewal path against a live SoftEther container: `ServerCertSet` →
  `Flush` → `docker restart` → server serves the new certificate, fingerprint
  matched. The no-renewal path correctly leaves the VPN server untouched.
- Ofelia parses the generated `config.ini` and drives the job on schedule.

### Known untested

- **http-01 end to end.** Argument construction and the `standalone` plugin were
  verified, but a real http-01 issuance needs a public domain pointing at the
  test host. dns-01 *is* verified end to end. See
  [How http-01 works without a web server](#how-http-01-works-without-a-web-server).
- **arm64 execution.** The test host is `x86_64` with no qemu/binfmt, so
  functional runs used the `linux/amd64` side of the same multi-arch manifests.
  The arm64 images exist (checked via `docker manifest inspect`) but were not
  executed.
- **The literal `/opt/softether` path.** `/opt` is root-owned and the installer
  was run with `BASE` redirected to a writable directory instead — identical
  logic, one string different.

Run `install_softether.sh` on the real ARM64 box to close all three.
