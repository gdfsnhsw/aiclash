#!/bin/bash

formyairportPath=/etc/subconverter/profiles/formyairport.ini

setconfig(){
	#参数1代表变量名，参数2代表变量值,参数3即文件路径
	[ -z "$3" ] && configpath=$formyairportPath || configpath=$3
	[ -n "$(grep ${1} $configpath)" ] && sed -i "s#${1}=.*#${1}=${2}#g" $configpath || echo "${1}=${2}" >> $configpath
}

sed -i '/url=*/'d $formyairportPath
setconfig url $URL

sed -i '/udp=*/'d $formyairportPath
setconfig udp $UDP

sed -i '/script=*/'d $formyairportPath
setconfig script $SCRIPT

while true; do
    supervisorctl status subconverter
    [ $? -eq 0 ] && \
    wget "http://127.0.0.1:25500/getprofile?name=profiles/formyairport.ini&token=password" -O config.yaml && \
    break
    echo -e "\033[32m正在启动subconverter并生成clash配置文件，请等待...\033[0m"
    sleep 3
done

supervisorctl restart clash
