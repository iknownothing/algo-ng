# MSS is the TCP Max Segment Size
# Setting the 'max_mss' variable can solve some issues related to packet fragmentation
# This appears to be necessary on (at least) Google Cloud,
# however, some routers also require a change to this parameter
# See also:
# - https://github.com/trailofbits/algo/issues/216
# - https://github.com/trailofbits/algo/issues?utf8=%E2%9C%93&q=is%3Aissue%20mtu
# - https://serverfault.com/questions/601143/ssh-not-working-over-ipsec-tunnel-strongswan
# max_mss = 1316
max_mss = 0

# Block traffic between connected clients
BetweenClients_DROP = true

# Upgrade the system during the deployment
system_upgrade = false

strongswan_log_level = "2"

adblock_lists = [
  "http://winhelp2002.mvps.org/hosts.txt",
  "https://adaway.org/hosts.txt",
  "https://www.malwaredomainlist.com/hostslist/hosts.txt",
  "https://hosts-file.net/ad_servers.txt"
]

# Your Algo server will automatically install security updates. Some updates
# require a reboot to take effect but your Algo server will not reboot itself
# automatically unless you change 'enabled' below from 'false' to 'true', in
# which case a reboot will take place if necessary at the time specified (as
# HH:MM) in the time zone of your Algo server. The default time zone is UTC.
unattended_reboot = {
  enabled = false
  time    = "06:00"
}

# DNS servers which will be used if 'dns_encryption' is 'true'. Multiple
# providers may be specified, but avoid mixing providers that filter results
# (like Cisco) with those that don't (like Cloudflare) or you could get
# inconsistent results. The list of available public providers can be found
# here:
# https://github.com/DNSCrypt/dnscrypt-resolvers/blob/master/v2/public-resolvers.md
dnscrypt_servers = {
  ipv4 = "cloudflare"
  ipv6 = "cloudflare-ipv6"
}

# DNS servers which will be used if 'dns_encryption' is 'false'.
# The default is to use Cloudflare.
ipv4_dns_servers = [
  "1.1.1.1",
  "1.0.0.1"
]

ipv6_dns_servers = [
  "2606:4700:4700::1111",
  "2606:4700:4700::1001"
]

# IP address for the local dns resolver
local_service_ip = "172.16.0.1"

unmanaged = false
