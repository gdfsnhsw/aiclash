#!/bin/bash

log() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*"
}

set_localnetwork() {
    log "[ipset] Setting localnetwork"
    if [ -z "${LOCALNETWORK}" ]; then
        LOCALNETWORK="127.0.0.0/8,10.0.0.0/8,192.168.0.0/16,224.0.0.0/4,172.16.0.0/12"
    fi
    IFS=',' read -ra LOCALNETWORK <<< "$LOCALNETWORK"
    ipset create localnetwork hash:net
    # append local machine ip
    hostnames=$(hostname -i)
    IFS=' ' read -ra hostnames <<< "$hostnames"
    for entry in "${hostnames[@]}"; do
        LOCALNETWORK+=("$entry")
    done

    for entry in "${LOCALNETWORK[@]}"; do
        log "[ipset] Adding '${entry}'"
        ipset add localnetwork ${entry}
    done
    log "[ipset] setting localnetwork done."
}

set_chnroute() {
    log "[ipset] Setting chnroute"
    # ipset -N chnroute hash:net maxelem 65536
    ipset create chnroute hash:net family inet hashsize 1024 maxelem 65536
    for ip in $(cat '/root/.config/clash/cn_rules.conf'); do
    ipset add chnroute $ip
    done
    log "[ipset] setting chnroute done."
}

gethost(){
	[ -z "$host" ] && host=$(ubus call network.interface.lan status 2>&1 | grep \"address\" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}';)
	[ -z "$host" ] && host=$(ip a 2>&1 | grep -w 'inet' | grep 'global' | grep -E '\ 1(92|0|72)\.' | sed 's/.*inet.//g' | sed 's/\/[0-9][0-9].*$//g' | head -n 1)
	[ -n "$host" ] && lanhost="-s $(echo $host | grep -oE '^1(92|0|72)\.')0.0.0/8"
}

readonly PROXY_BYPASS_USER="nobody"
# readonly PROXY_BYPASS_CGROUP="0x100000"
readonly PROXY_FWMARK="0x1"
readonly PROXY_ROUTE_TABLE="0x1"
readonly PROXY_DNS_PORT="1053"
readonly PROXY_TUN_DEVICE_NAME="utun"
readonly PROXY_REDIR_PORT="7892"
readonly PROXY_TPROXY_PORT="7893"
