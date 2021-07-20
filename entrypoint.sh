#!/bin/bash

set -e

echo -e "\033[32m======================== 1. 安装修改系统文件 =========================\033[0m"
# 开启转发，需要 privileged
# Deprecated! 容器默认已开启
echo "1" > /proc/sys/net/ipv4/ip_forward
echo 'nameserver 223.5.5.5'>>/etc/resolv.conf
apk add supervisor

echo -e "\033[32m======================== 2. 载入所需文件 ============================\033[0m"
if [ ! -e '/aiclash/subconverter/subconverter' ] ; then
    tar -zxvf /root/.config/subconverter/subconverter.tar.gz -C /aiclash/
    cp  /root/.config/subconverter/profiles/* /aiclash/subconverter/profiles
    mv -f /aiclash/subconverter/profiles/all_base.tpl /aiclash/subconverter/base/all_base.tpl
    echo -e "载入subconverter"
fi

if [ ! -e '/aiclash/clash/dashboard/index.html' ] || [ "$UPDATE" = "true" ] ; then
    mkdir -p /root/.config/clash/dashboard
    unzip -d /root/.config/clash/ /root/.config/clash/gh-pages.zip
    mv -f /root/.config/clash/clash-dashboard-gh-pages/* /root/.config/clash/dashboard
    cp -r /root/.config/clash/dashboard /aiclash/clash/dashboard
    echo -e "载入dashboard"
    
fi

#if [ ! -e '/aiclash/clash/config.yaml' ]; then
#    cp  /root/.config/clash/config.yaml /aiclash/clash/config.yaml
#    echo -e "载入clash_config.yaml成功"
#fi

#if [ ! -e '/aiclash/clash/Country.mmdb' ]; then
#    cp  /root/.config/clash/Country.mmdb /aiclash/clashCountry.mmdb
#    echo -e "载入Country.mmdb"   
#fi

if [ ! -e '/aiclash/getconfig.sh' ]; then
    cp  /usr/lib/clash/getconfig.sh /aiclash/getconfig.sh
    echo -e "载入shell.sh"   
fi

if [ ! -e '/aiclash/mosdns/config.yaml' ]; then
    cp  /root/.config/mosdns/config.yaml /aiclash/mosdns/config.yaml
    echo -e "载入mosdns_config.yaml"   
fi

if [ ! -e '/aiclash/mosdns/geoip.dat' ]; then
    cp  /root/.config/mosdns/geoip.dat /aiclash/mosdns/geoip.dat
    echo -e "载入geoip.dat"   
fi

if [ ! -e '/aiclash/mosdns/geosite.dat' ]; then
    cp  /root/.config/mosdns/geosite.dat /aiclash/mosdns/geosite.dat
    echo -e "载入geosite.dat"   
fi

echo -e "\033[32m======================== 3. 自定义路由表 ============================\033[0m"
if [ "$ROUTE_MODE" = "redir-tun" ] && [ "$CN_IP_ROUTE" = "true" ]; then
    echo -e "混合模式(绕过CN_IP)"
    /usr/lib/clash/set-redir-tun.sh cn_setup &
elif [ "$ROUTE_MODE" = "redir-tun" ] && [ "$CN_IP_ROUTE" = "false" ]; then
    echo -e "混合模式"
    /usr/lib/clash/set-redir-tun.sh setup &
elif [ "$ROUTE_MODE" = "tun" ] && [ "$CN_IP_ROUTE" = "true" ]; then
    echo -e "tun模式(绕过CN_IP)"
    /usr/lib/clash/set-tun.sh cn_setup &
elif [ "$ROUTE_MODE" = "tun" ] && [ "$CN_IP_ROUTE" = "false" ]; then
    echo -e "tun模式"
    /usr/lib/clash/set-tun.sh setup &    
elif [ "$ROUTE_MODE" = "tproxy" ] && [ "$CN_IP_ROUTE" = "true" ]; then
    echo -e "tproxy模式(绕过CN_IP)"
    /usr/lib/clash/set-tproxy.sh cn_setup &
elif [ "$ROUTE_MODE" = "tproxy" ] && [ "$CN_IP_ROUTE" = "false" ]; then
    echo -e "tproxy模式"
    /usr/lib/clash/set-tproxy.sh setup &
fi

echo -e "\033[32m======================== 4. 启动程序 ===============================\033[0m"
supervisord -c /etc/supervisord.conf
echo -e "supervisord启动成功..."

echo -e "\033[32m======================== 5. 是否自动生成config ======================\033[0m"
if [ $GET_CONFIG = true ]; then
    bash /aiclash/getconfig.sh
    echo -e "\033[32m===成功生成clash配置文件===\033[0m"
elif [ $GET_CONFIG = false ]; then
    echo -e "\033[32m===未设置生成config===\033[0m"
fi

tail -f /dev/null

exec "$@"
