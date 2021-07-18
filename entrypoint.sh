#!/bin/bash

set -e

echo -e "======================== 1. 开始自定义路由表 ========================\n"
if [ "$ROUTE_MODE" = "redir-tun" ]; then
    echo -e "\033[32m=混合模式=\033[0m"
    /usr/lib/clash/set-redir-tun.sh set1 &
elif [ "$ROUTE_MODE" = "redir-tun2" ]; then
    echo -e "\033[32m=混合模式]=\033[0m"
    /usr/lib/clash/set-redir-tun.sh set2 &
elif [ "$ROUTE_MODE" = "tun" ]; then
    echo -e "\033[32m=tun模式=\033[0m"
    /usr/lib/clash/set-tun.sh set1 &
elif [ "$ROUTE_MODE" = "tproxy" ]; then
    echo -e "\033[32m=tproxy模式=\033[0m"
    /usr/lib/clash/set-tproxy.sh set1 &
fi

# 开启转发，需要 privileged
# Deprecated! 容器默认已开启
echo "1" > /proc/sys/net/ipv4/ip_forward

echo 'nameserver 223.5.5.5'>>/etc/resolv.conf

apk add supervisor

echo -e "======================== 2. 载入所需文件 ============================\n"
if [ ! -e '/etc/subconverter/subconverter' ] ; then
    tar -zxvf /root/.config/subconverter/subconverter.tar.gz -C /etc/
    cp  /root/.config/subconverter/profiles/* /etc/subconverter/profiles
    mv -f /etc/subconverter/profiles/all_base.tpl /etc/subconverter/base/all_base.tpl
    echo -e "\033[32m载入subconverter\033[0m"
fi

if [ ! -e '/clash_config/dashboard/index.html' ] || [ "$UPDATE" = "true" ] ; then
    mkdir -p /root/.config/clash/dashboard
    unzip -d /root/.config/clash/ /root/.config/clash/gh-pages.zip
    mv -f /root/.config/clash/clash-dashboard-gh-pages/* /root/.config/clash/dashboard
    cp -r /root/.config/clash/dashboard /clash_config/dashboard
    echo -e "\033[32m载入dashboard\033[0m"
    
fi

#if [ ! -e '/clash_config/config.yaml' ]; then
#    cp  /root/.config/clash/config.yaml /clash_config/config.yaml
#    echo -e "\033[32m更新clash_config.yaml成功\033[0m"
#fi

if [ ! -e '/clash_config/Country.mmdb' ]; then
    cp  /root/.config/clash/Country.mmdb /clash_config/Country.mmdb
    cp  /usr/lib/clash/shell.sh /clash_config/shell.sh
    echo -e "\033[32m载入Country.mmdb\033[0m"   
fi

if [ ! -e '/clash_config/shell.sh' ]; then
    cp  /usr/lib/clash/shell.sh /clash_config/shell.sh
    echo -e "\033[32m载入shell.sh\033[0m"   
fi

if [ ! -e '/etc/mosdns/config.yaml' ]; then
    cp  /root/.config/mosdns/config.yaml /etc/mosdns/config.yaml
    echo -e "\033[32m载入mosdns_config.yaml\033[0m"   
fi

if [ ! -e '/etc/mosdns/geoip.dat' ]; then
    cp  /root/.config/mosdns/geoip.dat /etc/mosdns/geoip.dat
    echo -e "\033[32m载入geoip.dat\033[0m"   
fi

if [ ! -e '/etc/mosdns/geosite.dat' ]; then
    cp  /root/.config/mosdns/geosite.dat /etc/mosdns/geosite.dat
    echo -e "\033[32m载入geosite.dat\033[0m"   
fi

supervisord -c /etc/supervisord.conf
echo -e "supervisord启动成功..."


echo -e "======================== 3. 自定义shell代码 ========================\n"
if [[ $SHELL == true ]]; then
    bash /clash_config/shell.sh
    echo -e "自定义shell代码执行成功..."
elif [[ $SHELL == false ]]; then
    echo -e "自定义shell代码未设置"
fi



tail -f /dev/null

exec "$@"
