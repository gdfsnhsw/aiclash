#!/bin/bash

set -e

echo -e "\033[32m======================== 1. 安装修改系统文件 =========================\033[0m"
# 开启转发，需要 privileged
# Deprecated! 容器默认已开启
echo "1" > /proc/sys/net/ipv4/ip_forward
echo 'nameserver 223.5.5.5'>>/etc/resolv.conf
apk add supervisor

echo -e "\033[32m======================== 2. 自定义路由表 ============================\033[0m"
if [ "$ROUTE_MODE" = "redir-tun" ]; then
    echo -e "混合模式"
    /usr/lib/clash/set-redir-tun.sh set1 &
elif [ "$ROUTE_MODE" = "redir-tun2" ]; then
    echo -e "混合模式]"
    /usr/lib/clash/set-redir-tun.sh set2 &
elif [ "$ROUTE_MODE" = "tun" ]; then
    echo -e "tun模式"
    /usr/lib/clash/set-tun.sh set1 &
elif [ "$ROUTE_MODE" = "tproxy" ]; then
    echo -e "tproxy模式"
    /usr/lib/clash/set-tproxy.sh set1 &
fi

echo -e "\033[32m======================== 3. 载入所需文件 ============================\033[0m"
if [ ! -e '/etc/subconverter/subconverter' ] ; then
    tar -zxvf /root/.config/subconverter/subconverter.tar.gz -C /etc/
    cp  /root/.config/subconverter/profiles/* /etc/subconverter/profiles
    mv -f /etc/subconverter/profiles/all_base.tpl /etc/subconverter/base/all_base.tpl
    echo -e "载入subconverter"
fi

if [ ! -e '/clash_config/dashboard/index.html' ] || [ "$UPDATE" = "true" ] ; then
    mkdir -p /root/.config/clash/dashboard
    unzip -d /root/.config/clash/ /root/.config/clash/gh-pages.zip
    mv -f /root/.config/clash/clash-dashboard-gh-pages/* /root/.config/clash/dashboard
    cp -r /root/.config/clash/dashboard /clash_config/dashboard
    echo -e "载入dashboard"
    
fi

#if [ ! -e '/clash_config/config.yaml' ]; then
#    cp  /root/.config/clash/config.yaml /clash_config/config.yaml
#    echo -e "\033[32m更新clash_config.yaml成功\033[0m"
#fi

if [ ! -e '/clash_config/Country.mmdb' ]; then
    cp  /root/.config/clash/Country.mmdb /clash_config/Country.mmdb
    cp  /usr/lib/clash/shell.sh /clash_config/shell.sh
    echo -e "载入Country.mmdb"   
fi

if [ ! -e '/clash_config/shell.sh' ]; then
    cp  /usr/lib/clash/shell.sh /clash_config/shell.sh
    echo -e "载入shell.sh"   
fi

if [ ! -e '/etc/mosdns/config.yaml' ]; then
    cp  /root/.config/mosdns/config.yaml /etc/mosdns/config.yaml
    echo -e "载入mosdns_config.yaml"   
fi

if [ ! -e '/etc/mosdns/geoip.dat' ]; then
    cp  /root/.config/mosdns/geoip.dat /etc/mosdns/geoip.dat
    echo -e "载入geoip.dat"   
fi

if [ ! -e '/etc/mosdns/geosite.dat' ]; then
    cp  /root/.config/mosdns/geosite.dat /etc/mosdns/geosite.dat
    echo -e "载入geosite.dat"   
fi

echo -e "\033[32m======================== 4. 启动程序 ===============================\033[0m"
supervisord -c /etc/supervisord.conf
echo -e "supervisord启动成功..."

echo -e "\033[32m======================== 5. 自定义shell代码 ========================\033[0m"
if [ $SHELL = true ]; then
    bash /clash_config/shell.sh
    echo -e "自定义shell代码执行成功..."
elif [ $SHELL = false ]; then
    echo -e "自定义shell代码未设置"
fi

tail -f /dev/null

exec "$@"
