#!/bin/bash

source /usr/lib/clash/common.sh

sed -i '/url=*/'d $formyairportPath
setconfig url $URL

while true; do
    supervisorctl status subconverter
    [ $? -eq 0 ] && wget "http://127.0.0.1:25500/getprofile?name=profiles/formyairport.ini&token=password" -O config.yaml && break
    echo -e "\033[32m正在启动subconverter，请等待...\033[0m"
    sleep 3
done
