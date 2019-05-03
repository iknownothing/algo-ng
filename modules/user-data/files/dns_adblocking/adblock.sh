#!/bin/sh
# Block ads, malware, etc..

TEMP="$(mktemp)"
TEMP_SORTED="$(mktemp)"
DNSMASQ_WHITELIST="/var/lib/dnsmasq/white.list"
DNSMASQ_BLACKLIST="/var/lib/dnsmasq/black.list"
DNSMASQ_BLOCKHOSTS="/etc/dnsmasq.d/block.hosts.conf"
BLOCKLIST_URLS="/etc/default/adblock"

#Delete the old block.hosts to make room for the updates
rm -f $DNSMASQ_BLOCKHOSTS

echo 'Downloading hosts lists...'
#Download and process the files needed to make the lists (enable/add more, if you want)
while read url; do
  wget --timeout=2 --tries=3 -qO- "$url" | grep -Ev "(localhost)" | grep -Ew "(0.0.0.0|127.0.0.1)" | awk '{sub(/\r$/,"");print $2}'  >> "$TEMP"
done < $BLOCKLIST_URLS

#Add black list, if non-empty
if [ -s "$DNSMASQ_BLACKLIST" ]
then
    echo 'Adding blacklist...'
    cat $DNSMASQ_BLACKLIST >> "$TEMP"
fi

#Sort the download/black lists
awk '/^[^#]/ { print "local=/" $1 "/" }' "$TEMP" | sort -u > "$TEMP_SORTED"

#Filter (if applicable)
if [ -s "$DNSMASQ_WHITELIST" ]
then
    #Filter the blacklist, suppressing whitelist matches
    #  This is relatively slow =-(
    echo 'Filtering white list...'
    grep -v -E "^[[:space:]]*$" $DNSMASQ_WHITELIST | awk '/^[^#]/ {sub(/\r$/,"");print $1}' | grep -vf - "$TEMP_SORTED" > $DNSMASQ_BLOCKHOSTS
else
    cat "$TEMP_SORTED" > $DNSMASQ_BLOCKHOSTS
fi

exit 0
