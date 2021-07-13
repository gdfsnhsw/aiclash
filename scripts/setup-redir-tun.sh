#!/bin/bash

set_ipt() {
    source /usr/lib/clash/common.sh

    while true; do
        ip link show $PROXY_TUN_DEVICE_NAME
        [ $? -eq 0 ] && break
        sleep 1
    done

    if [ "${EN_MODE:-fake-ip}" = "fake-ip" ]; then
        ip tuntap add "$TUN_DEV" mode tun user $CLASH_USER
        ip link set "$TUN_DEV" up
        ip addr add "$TUN_NET" dev "$TUN_DEV"
    else
        gethost
        set_localnetwork

        #/opt/script/setup-clash-cgroup.sh

        ip route replace default dev "$PROXY_TUN_DEVICE_NAME" table "$PROXY_ROUTE_TABLE"

        ip rule add fwmark "$PROXY_FWMARK" lookup "$PROXY_ROUTE_TABLE"

        iptables -t nat -N CLASH
        iptables -t nat -F CLASH
        #iptables -t nat -A CLASH -m owner --uid-owner "$PROXY_BYPASS_USER" -j RETURN

        #iptables -t nat -A CLASH -m owner --uid-owner systemd-timesync -j RETURN
        #iptables -t nat -A CLASH -m cgroup --cgroup "$PROXY_BYPASS_CGROUP" -j RETURN
        #iptables -t nat -A CLASH -m addrtype --dst-type BROADCAST -j RETURN
        iptables -t nat -A CLASH -m set --match-set localnetwork dst -j RETURN
        iptables -t nat -A CLASH -p tcp -j REDIRECT --to-ports "$PROXY_REDIR_PORT"
        iptables -t nat -A PREROUTING -p tcp $lanhost -j CLASH
        #Google home DNS特殊处理
        iptables -t nat -I PREROUTING -p tcp -d 8.8.8.8 -j CLASH
        iptables -t nat -I PREROUTING -p tcp -d 8.8.4.4 -j CLASH
    
        iptables -I FORWARD -o "$PROXY_TUN_DEVICE_NAME" -j ACCEPT

        iptables -t nat -N CLASH_DNS
        iptables -t nat -F CLASH_DNS
        #iptables -t nat -A CLASH_DNS -d 127.0.0.0/8 -j RETURN
        #iptables -t nat -A CLASH_DNS -m owner --uid-owner "$PROXY_BYPASS_USER" -j RETURN
        #iptables -t nat -A CLASH_DNS -m owner --uid-owner systemd-timesync -j RETURN
        #iptables -t nat -A CLASH_DNS -m cgroup --cgroup "$PROXY_BYPASS_CGROUP" -j RETURN
        iptables -t nat -A CLASH_DNS -p udp --dport 53 -j REDIRECT --to "$PROXY_DNS_PORT"
        iptables -t nat -A CLASH_DNS -p tcp --dport 53 -j REDIRECT --to "$PROXY_DNS_PORT"

        iptables -t nat -A PREROUTING -p udp -j CLASH_DNS
    
    fi

    ip addr

    fireqos start
}


set_nft() {
    source /usr/lib/clash/common.sh

    while true; do
        ip link show utun
        [ $? -eq 0 ] && break
        sleep 1
    done

    ip tuntap add utun mode tun user nobaby
    ip link set utun up
    ip addr add "198.18.0.1/16" dev utun

    ip route replace default dev utun table 114

    ip rule del fwmark 114514 lookup 114 > /dev/null 2> /dev/null
    ip rule add fwmark 114514 lookup 114
    
    nft -f /usr/lib/clash/nft_redir-tun.conf
    
    #sysctl -w net/ipv4/ip_forward=1

    ip addr

    fireqos start
}
