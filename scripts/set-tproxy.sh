#!/bin/bash

_setup1(){

    while true; do
        ip link show utun
        [ $? -eq 0 ] && break
        echo -e "\033[32m正在启动clash，请等待...\033[0m"
        sleep 3
    done

#    ip tuntap add utun mode tun user nobody
#    ip link set utun up
#    ip addr add "198.18.0.1/16" dev utun

    ip route replace local default dev lo table 114

    ip rule del fwmark 114514 lookup 114 > /dev/null 2> /dev/null
    ip rule add fwmark 114514 lookup 114

    nft -f /usr/lib/clash/nft_tproxy.conf

    ip addr
    
    #sysctl -w net/ipv4/ip_forward=1

    exit 0

}

_setup2(){

    while true; do
        ip link show utun
        [ $? -eq 0 ] && break
        echo -e "\033[32m正在启动clash，请等待...\033[0m"
        sleep 3
    done

#    ip tuntap add utun mode tun user nobody
#    ip link set utun up
#    ip addr add "198.18.0.1/16" dev utun

    ip route replace local default dev lo table 114

    ip rule del fwmark 114514 lookup 114 > /dev/null 2> /dev/null
    ip rule add fwmark 114514 lookup 114

    nft -f - << EOF
    define LOCAL_SUBNET = { 10.0.0.0/8, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 }
    table clash
    flush table clash
    table clash {
        chain forward {
            type filter hook prerouting priority 0;
            ip protocol != { tcp, udp } accept
            ip daddr \$LOCAL_SUBNET accept
            ip protocol tcp mark set $NETFILTER_MARK tproxy to 127.0.0.1:7893
            ip protocol udp mark set $NETFILTER_MARK tproxy to 127.0.0.1:7893
        }
        chain forward-dns-redirect {
            type nat hook prerouting priority 0; policy accept;           
            ip protocol != { tcp, udp } accept        
            ip daddr \$LOCAL_SUBNET tcp dport 53 dnat :5352
            ip daddr \$LOCAL_SUBNET udp dport 53 dnat :5352
        }
    }
EOF

    ip addr
    
    #sysctl -w net/ipv4/ip_forward=1

    exit 0

}

case "$1" in
"set1") _setup1;;
"set2") _setup2;;
esac
