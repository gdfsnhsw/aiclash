#!/bin/bash

set -e

if [ "$ROUTE_MODE" = "redir-tun" ]; then
    echo -e "\033[32m=======Redirect TCP and transfer UDP to utun device[redir-tun模式(混合模式)]=======\033[0m"
    /usr/lib/clash/set-redir-tun.sh set1 &
elif [ "$ROUTE_MODE" = "redir-tun2" ]; then
    echo -e "\033[32m=======Redirect TCP and transfer UDP to utun device[redir-tun模式(混合模式)]=======\033[0m"
    /usr/lib/clash/set-redir-tun.sh set2 &
elif [ "$ROUTE_MODE" = "tun" ]; then
    echo -e "\033[32m================Transfer TCP and UDP to utun device[tun模式]======================\033[0m"
    /usr/lib/clash/set-tun.sh &
elif [ "$ROUTE_MODE" = "tproxy" ]; then
    echo -e "\033[32m===================TProxy TCP and TProxy UDP[tproxy模式]==========================\033[0m"
    /usr/lib/clash/set-tproxy.sh &
fi


# 开启转发，需要 privileged
# Deprecated! 容器默认已开启
echo "1" > /proc/sys/net/ipv4/ip_forward

echo 'nameserver 223.5.5.5'>>/etc/resolv.conf

if [ ! -e '/clash_config/dashboard/index.html' ] || [ "$UPDATE" = "true" ] ; then
    mkdir -p /root/.config/clash/dashboard
    unzip -d /root/.config/clash/ /root/.config/clash/gh-pages.zip
    mv -f /root/.config/clash/clash-dashboard-gh-pages/* /root/.config/clash/dashboard
    cp -r /root/.config/clash/dashboard /clash_config/dashboard
    echo -e "\033[32m=======更新dashboard成功================\033[0m"
fi

if [ ! -e '/clash_config/config.yaml' ]; then
    cp  /root/.config/clash/config.yaml /clash_config/config.yaml
    cp  /usr/lib/clash/shell.sh /clash_config/shell.sh
    echo -e "\033[32m=======更新clash_config.yaml成功========\033[0m"
fi

if [ ! -e '/clash_config/Country.mmdb' ]; then
    cp  /root/.config/clash/Country.mmdb /clash_config/Country.mmdb
    echo -e "\033[32m=======更新Country.mmdb成功=============\033[0m"   
fi

if [ ! -e '/etc/mosdns/config.yaml' ]; then
    cp  /root/.config/mosdns/config.yaml /etc/mosdns/config.yaml
    echo -e "\033[32m=======更新mosdns_config.yaml成功=======\033[0m"   
fi

if [ ! -e '/etc/mosdns/geoip.dat' ]; then
    cp  /root/.config/mosdns/geoip.dat /etc/mosdns/geoip.dat
    echo -e "\033[32m=======更新geoip.dat成功================\033[0m"   
fi

if [ ! -e '/etc/mosdns/geosite.dat' ]; then
    cp  /root/.config/mosdns/geosite.dat /etc/mosdns/geosite.dat
    echo -e "\033[32m=======更新geosite.dat成功==============\033[0m"   
fi

if [ ! -e '/etc/subconverter/subconverter' ] ; then
    tar -zxvf /root/.config/subconverter/subconverter.tar.gz -C /etc/
    cp  /root/.config/subconverter/profiles/* /etc/subconverter/profiles
fi

bash /clash_config/shell.sh

apk add supervisor
supervisord -c /etc/supervisord.conf
echo -e "supervisord启动成功..."

tail -f /dev/null

exec "$@"
