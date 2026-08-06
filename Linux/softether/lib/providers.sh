#!/usr/bin/env bash
# Certbot DNS provider metadata, used by install.sh to know what to ask for.
#
# Field data was taken from each plugin's own source in the certbot repo
# (_add_provider_option / credentials.conf calls), not from memory, so the INI
# keys below are exactly what the plugins read.
#
# Format of provider_fields(): one field per line
#   <ini_key>|<prompt>|<secret?>|<default>
# secret? = "s" to hide typing, "p" for plain.
# An empty default means the field is required.

DNS_PROVIDERS="cloudflare digitalocean dnsimple dnsmadeeasy gehirn google linode luadns nsone ovh rfc2136 route53 sakuracloud"

# Default --dns-<p>-propagation-seconds, per plugin source.
provider_propagation() {
  case "$1" in
    cloudflare|digitalocean)      echo 10  ;;
    dnsimple|gehirn|luadns|nsone|sakuracloud) echo 30 ;;
    dnsmadeeasy|google|rfc2136)   echo 60  ;;
    linode|ovh)                   echo 120 ;;
    route53)                      echo 30  ;;
    *)                            echo 60  ;;
  esac
}

provider_label() {
  case "$1" in
    cloudflare)   echo "Cloudflare" ;;
    digitalocean) echo "DigitalOcean" ;;
    dnsimple)     echo "DNSimple" ;;
    dnsmadeeasy)  echo "DNS Made Easy" ;;
    gehirn)       echo "Gehirn Infrastructure Service" ;;
    google)       echo "Google Cloud DNS" ;;
    linode)       echo "Linode" ;;
    luadns)       echo "LuaDNS" ;;
    nsone)        echo "NS1" ;;
    ovh)          echo "OVH" ;;
    rfc2136)      echo "RFC 2136 (BIND dynamic update)" ;;
    route53)      echo "Amazon Route 53" ;;
    sakuracloud)  echo "Sakura Cloud" ;;
  esac
}

# Where to go get the credentials, shown before prompting.
provider_hint() {
  case "$1" in
    cloudflare)   echo "Cloudflare dashboard -> My Profile -> API Tokens. A scoped token needs Zone:DNS:Edit." ;;
    digitalocean) echo "DigitalOcean -> API -> Tokens, with write scope." ;;
    dnsimple)     echo "DNSimple -> Account -> Automation -> API tokens." ;;
    dnsmadeeasy)  echo "DNS Made Easy -> Config -> Account Information -> API Key / Secret Key (API access must be enabled)." ;;
    gehirn)       echo "Gehirn Infrastructure Service -> API keys." ;;
    google)       echo "GCP service account JSON with dns.admin (or a role granting dns.changes.* and dns.resourceRecordSets.*)." ;;
    linode)       echo "Linode Cloud Manager -> My Profile -> API Tokens, with Domains read/write." ;;
    luadns)       echo "LuaDNS -> Settings -> API, using your account email plus the API token." ;;
    nsone)        echo "NS1 portal -> Account Settings -> API Keys." ;;
    ovh)          echo "Create keys at https://api.ovh.com/createToken/ with GET/POST/PUT/DELETE on /domain/zone/*" ;;
    rfc2136)      echo "The TSIG key from your BIND server's named.conf (key name + secret + algorithm)." ;;
    route53)      echo "An IAM user/role permitted to do route53:ChangeResourceRecordSets and ListHostedZones on the zone." ;;
    sakuracloud)  echo "Sakura Cloud control panel -> API keys." ;;
  esac
}

# Credential style: "ini" (a .ini file), "json" (a key file), "env" (env vars).
provider_cred_style() {
  case "$1" in
    google)  echo json ;;
    route53) echo env  ;;
    *)       echo ini  ;;
  esac
}

provider_fields() {
  case "$1" in
    cloudflare)
      # The plugin accepts either a scoped API token, or the legacy
      # email + global API key pair. CF_AUTH is set by install.sh.
      if [[ "${CF_AUTH:-token}" == "token" ]]; then
        echo "dns_cloudflare_api_token|Cloudflare API token|s|"
      else
        echo "dns_cloudflare_email|Cloudflare account email|p|"
        echo "dns_cloudflare_api_key|Cloudflare global API key|s|"
      fi
      ;;
    digitalocean)
      echo "dns_digitalocean_token|DigitalOcean API token|s|" ;;
    dnsimple)
      echo "dns_dnsimple_token|DNSimple API token|s|" ;;
    dnsmadeeasy)
      echo "dns_dnsmadeeasy_api_key|DNS Made Easy API key|s|"
      echo "dns_dnsmadeeasy_secret_key|DNS Made Easy secret key|s|" ;;
    gehirn)
      echo "dns_gehirn_api_token|Gehirn API token|s|"
      echo "dns_gehirn_api_secret|Gehirn API secret|s|" ;;
    linode)
      echo "dns_linode_key|Linode API key|s|" ;;
    luadns)
      echo "dns_luadns_email|LuaDNS account email|p|"
      echo "dns_luadns_token|LuaDNS API token|s|" ;;
    nsone)
      echo "dns_nsone_api_key|NS1 API key|s|" ;;
    ovh)
      echo "dns_ovh_endpoint|OVH API endpoint|p|ovh-eu"
      echo "dns_ovh_application_key|OVH application key|s|"
      echo "dns_ovh_application_secret|OVH application secret|s|"
      echo "dns_ovh_consumer_key|OVH consumer key|s|" ;;
    rfc2136)
      echo "dns_rfc2136_server|Target DNS server IP|p|"
      echo "dns_rfc2136_port|DNS server port|p|53"
      echo "dns_rfc2136_name|TSIG key name|p|"
      echo "dns_rfc2136_secret|TSIG key secret|s|"
      echo "dns_rfc2136_algorithm|TSIG algorithm|p|HMAC-SHA512" ;;
    sakuracloud)
      echo "dns_sakuracloud_api_token|Sakura Cloud API token|s|"
      echo "dns_sakuracloud_api_secret|Sakura Cloud API secret|s|" ;;
    route53)
      echo "AWS_ACCESS_KEY_ID|AWS access key ID|p|"
      echo "AWS_SECRET_ACCESS_KEY|AWS secret access key|s|" ;;
    google)
      ;;  # handled separately: a JSON key file is copied into place
  esac
}
