
    . /usr/lib/clash/common.sh

    ip route replace local default dev lo table "$IPROUTE2_TABLE_ID"

    ip rule del fwmark "$NETFILTER_MARK" lookup "$IPROUTE2_TABLE_ID" > /dev/null 2> /dev/null
    ip rule add fwmark "$NETFILTER_MARK" lookup "$IPROUTE2_TABLE_ID"

    nft -f /usr/lib/clash/tproxy.conf
    
   # sysctl -w net/ipv4/ip_forward=1
