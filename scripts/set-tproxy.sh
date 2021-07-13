#!/bin/bash

source /usr/lib/clash/common.sh

while true; do
    ip link show utun
    [ $? -eq 0 ] && break
    sleep 1
done

ip route replace local default dev lo table 114

ip rule del fwmark 114514 lookup 114 > /dev/null 2> /dev/null
ip rule add fwmark 114514 lookup 114

nft -f /usr/lib/clash/nft_tproxy.conf
    
# sysctl -w net/ipv4/ip_forward=1

ip addr

fireqos start
