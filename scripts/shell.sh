#!/bin/bash

source /usr/lib/clash/common.sh

sed -i '/url=*/'d $formyairportPath
setconfig url $URL

wget "http://127.0.0.1:25500/getprofile?name=profiles/formyairport.ini&token=password" -O clash_config.yaml
