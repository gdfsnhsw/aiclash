#!/bin/bash

source /usr/lib/clash/common.sh

while true; do
    ip link show utun
    [ $? -eq 0 ] && break
    sleep 1
done

ip tuntap add utun mode tun user nobody
ip link set utun up
ip addr add "198.18.0.1/16" dev utun

ip route replace default dev utun table 114

ip rule del fwmark 114514 lookup 114 > /dev/null 2> /dev/null
ip rule add fwmark 114514 lookup 114
    
nft -f /usr/lib/clash/nft_redir-tun.conf
    
#sysctl -w net/ipv4/ip_forward=1
    
ip addr

fireqos start

