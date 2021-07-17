#!/bin/bash
formyairportPath=/etc/subconverter/profiles/formyairport.ini

setconfig(){
	#参数1代表变量名，参数2代表变量值,参数3即文件路径
	[ -z "$3" ] && configpath=$formyairportPath || configpath=$3
	[ -n "$(grep ${1} $configpath)" ] && sed -i "s#${1}=.*#${1}=${2}#g" $configpath || echo "${1}=${2}" >> $configpath
}

sed -i '/url=*/'d $formyairportPath
setconfig url $URL
