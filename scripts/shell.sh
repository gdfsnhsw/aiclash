#!/bin/bash

source /usr/lib/clash/common.sh

sed -i '/url=*/'d $formyairportPath
setconfig url $URL
