#!/bin/bash

set -e

if [ -n "$EN_MODE_TUN" ]; then
    #TUN模式
    /usr/lib/clash/setup-tun.sh &
else
    /usr/lib/clash/setup-tproxy.sh &
fi

# 开启转发，需要 privileged
# Deprecated! 容器默认已开启
echo "1" > /proc/sys/net/ipv4/ip_forward

if [ ! -e '/clash_config/dashboard/index.html' ] || [ "$UPDATE" = "true" ] ; then
    mkdir -p /root/.config/clash/dashboard
    unzip -d /root/.config/clash/ /root/.config/clash/gh-pages.zip
    mv -f /root/.config/clash/clash-dashboard-gh-pages/* /root/.config/clash/dashboard
    cp -r /root/.config/clash/dashboard /clash_config/dashboard
    echo -e "\033[32m=======更新dashboard成功=======\033[0m"
fi

if [ ! -e '/clash_config/config.yaml' ]; then
    cp  /root/.config/clash/config.yaml /clash_config/config.yaml
    echo -e "\033[32m=======更新config.yaml成功=======\033[0m"
fi

if [ ! -e '/clash_config/Country.mmdb' ]; then
    cp  /root/.config/clash/Country.mmdb /clash_config/Country.mmdb
    echo -e "\033[32m=======更新Country.mmdb成功=======\033[0m"   
fi

if [ ! -e '/etc/subconverter/subconverter' ] ; then
    tar -zxvf /root/.config/clash/subconverter.tar.gz -C /etc/
fi

# apk add supervisor
supervisord -c /etc/supervisord.conf
echo -e "supervisord启动..."

tail -f /dev/null

exec "$@"
