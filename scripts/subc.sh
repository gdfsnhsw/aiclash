#!/bin/bash

####定义目录####
#clash目录文件位置
clashPath=/srv/clash
#subconverter配置档案
formyairportPath=/srv/subconverter/profiles/formyairport.ini
#subconverter配置档案备份
formyairportPathbak=/srv/subconverter/profiles/formyairport.ini.bak
#clash配置文件
yamlPath=$clashPath/config.yaml
#clash配置文件备份
yamlPathbak=$clashPath/config.yaml.bak
#clash配置文件新建
yamlPathnew=/tmp/clash_config.yaml
#clash核心位置
clashcorePath=/usr/bin/clash
#subc.sh位置
subcPath=/srv/subconverter/profiles/subc.sh
#判断clash进程是否运行
PIDS=`ps -ef|grep "$clashcorePath"|grep -v grep`
#clash重启命令
#supervisorctl restart clash  
#systemctl restart clash.service

setconfig(){
	#参数1代表变量名，参数2代表变量值,参数3即文件路径
	[ -z "$3" ] && configpath=$formyairportPath || configpath=$3
	[ -n "$(grep ${1} $configpath)" ] && sed -i "s#${1}=.*#${1}=${2}#g" $configpath || echo "${1}=${2}" >> $configpath
}

errornum(){
	echo -----------------------------------------------
	echo -e "\033[31m请输入正确的数字！\033[0m"
}

subcstart(){
	echo -----------------------------------------------
	echo -e "\033[44m             欢迎使用subc             \033[0m"
	echo -----------------------------------------------
	echo -e "  1.更新\033[34m配置文件\033[0m"
  echo -e "  2.生成\033[33m订阅模版\033[0m"
 	echo -e "  3.\033[35m重启\033[0m"clash
	echo -e "  4.设置\033[32m定时任务\033[0m"
	echo -----------------------------------------------
	echo -e "  q.\033[36m退出\033[0m"
	echo -----------------------------------------------
	read -p "请输入对应数字 > " num
	if [ "$num" = 1 ];then
	  getyaml
	elif [ "$num" = 2 ];then	  
  	  getlink
	elif [ "$num" = 3 ];then
  	  supervisorctl restart clash
	elif [ "$num" = 4 ];then
  	  clashcron
	elif [ "$num" = q ];then
    exit 0
	else
    errornum
    subcstart
	fi
}

clashrestart(){
	echo -----------------------------------------------
    read -p "是否重启clash？[1/0] > " res
	if [ "$res" = '1' ]; then
	  supervisorctl restart clash	
	elif [ "$res" = '0' ]; then
	  subcstart
  fi

}

getudp(){
	echo -----------------------------------------------
    read -p "是否开启udp？[1/0] > " res
	if [ "$res" = '1' ]; then
    sed -i '/udp=*/'d $formyairportPath
  	setconfig udp true	
	elif [ "$res" = '0' ]; then
    sed -i '/udp=*/'d $formyairportPath
		setconfig udp false
  else
    errornum
    getudp
  fi
}

linkconfig(){
	echo -----------------------------------------------
	echo 1	yuanlam养老版（推荐）
	echo 2	Loyalsoldier+奈飞分流（推荐）
	echo 3	ACL4SSR通用版无去广告（推荐）
	echo 4	ACL4SSR精简全能版（推荐）
	echo 5	ACL4SSR通用版+去广告加强
	echo 6	ACL4SSR精简版+去广告加强
	echo 7	ACL4SSR重度全分组+奈飞分流
	echo 8	ACL4SSR重度全分组+去广告加强
  echo -----------------------------------------------
	read -p "请输入对应数字[1-8] > " num
	if [ "$num" = 1 ];then
    sed -i '/config=*/'d $formyairportPath
		setconfig config config/yuanlam.ini  
	elif [ "$num" = 2 ];then
    sed -i '/config=*/'d $formyairportPath
		setconfig config config/Loyalsoldier.ini
	elif [ "$num" = 3 ];then
    sed -i '/config=*/'d $formyairportPath
		setconfig config config/ACL4SSR_Online_NoReject.ini
	elif [ "$num" = 4 ];then
    sed -i '/config=*/'d $formyairportPath
		setconfig config config/ACL4SSR_Online_Mini_MultiMode.ini	  
	elif [ "$num" = 5 ];then
    sed -i '/config=*/'d $formyairportPath
		setconfig config config/ACL4SSR_Online_AdblockPlus.ini
	elif [ "$num" = 6 ];then
    sed -i '/config=*/'d $formyairportPath
		setconfig config config/ACL4SSR_Online_Mini_AdblockPlus.ini  
	elif [ "$num" = 7 ];then
    sed -i '/config=*/'d $formyairportPath
		setconfig config config/ACL4SSR_Online_Full_Netflix.ini
	elif [ "$num" = 8 ];then
    sed -i '/config=*/'d $formyairportPath
		setconfig config config/ACL4SSR_Online_Full_AdblockPlus.ini
  else
    errornum
    linkconfig			  
	fi
}

getlink(){
	echo -----------------------------------------------
	echo -e "\033[44m如果你需要将多个订阅合成一份, 使用 '|' 来分隔链接, 可以按以下操作:\033[0m"
	echo -e "\033[33mhttps://dler.cloud/aaa|trojan://密码@域名:443#名称\033[0m"
  echo -----------------------------------------------
  stty erase '^H'
	read -p "请输入完整链接 > " link
	test=$(echo $link | grep "://")
	if [ -n "$link" -a -n "$test" ];then
		echo -----------------------------------------------
		echo -e 请检查输入的链接是否正确：
		echo -e "\033[32m$link\033[0m"
		echo -----------------------------------------------
		read -p "确认导入订阅链接？[1/0] > " res
			if [ "$res" = '1' ]; then
        mkyamlbak
				sed -i '/url=*/'d $formyairportPath
				setconfig url $link
        getudp
				linkconfig
        echo -----------------------------------------------
        echo -e   "\033[44m订阅模版完成，请选择<1.更新配置文件>\033[0m"
        subcstart
			elif [ "$res" = '0' ]; then
				getlink
      else
	    	errornum
        subcstart
      fi
	else
		echo -----------------------------------------------
		echo -e "\033[31m请输入正确的配置文件链接地址！！！\033[0m"
		sleep 1
    subcstart
	fi
}

mkyamlbak(){
  mkdir -p $clashPath
  if [ ! -e "$yamlPath" ];then
cat << EOF > /tmp/config.yaml
mixed-port: 7890
EOF
  mv /tmp/config.yaml $yamlPath 
  cp -r $yamlPath $yamlPathbak
  cp -r $formyairportPath $formyairportPathbak
  fi
}

keepyaml2(){
  if [ "$PIDS" = "" ]; then
    echo -----------------------------------------------
    echo -e clash启动失败，还原配置文件
    cp -r $yamlPathbak $yamlPath
    cp -r $formyairportPathbak $formyairportPath
    supervisorctl restart clash
  else
    echo -----------------------------------------------
    echo -e clash启动成功，http://localhost:9090/ui/
    echo -----------------------------------------------
  fi
}

keepyaml(){
		if [ -s $yamlPathnew  ];then
      cp -r $yamlPathnew $yamlPath
      echo -e "\033[32m已成功获取配置文件！\033[0m"
	    rm -rf $yamlPathnew
      supervisorctl restart clash
      keepyaml2
		else
			echo -----------------------------------------------
			echo -e "\033[32m创建配置文件失败！请选择<2.生成订阅模版>\033[0m"
			echo -----------------------------------------------
      rm -rf $yamlPathnew 
			subcstart
		fi
}

getyaml(){
    mkyamlbak  
	echo -e "\033[32m正在创建配置文件\033[0m"
    echo -----------------------------------------------
    wget "http://127.0.0.1:25500/getprofile?name=profiles/formyairport.ini&token=password" -O $yamlPathnew
    keepyaml
}

clashcron(){

	setcron(){
		setcrontab(){
			#设置具体时间
			echo -----------------------------------------------
      stty erase '^H'
			read -p "请输入小时（0-23） > " num
			if [ -z "$num" ]; then 
				errornum
				setcron
			elif [ $num -gt 23 ] || [ $num -lt 0 ]; then 
				errornum
				setcron
			else	
				hour=$num
				echo -----------------------------------------------
        stty erase '^H'
				read -p "请输入分钟（0-59） > " num
				if [ -z "$num" ]; then 
					errornum
					setcron
				elif [ $num -gt 59 ] || [ $num -lt 0 ]; then 
					errornum
					setcron
				else	
					min=$num
						echo -----------------------------------------------
						echo 将在$week1的$hour点$min分$cronname（旧的任务会被覆盖）
						read -p  "是否确认添加定时任务？(1/0) > " res
						if [ "$res" = '1' ]; then
							cronwords="$min $hour * * $week $cronset >/dev/null 2>&1 #$week1的$hour点$min分$cronname"
							crontab -l > /tmp/conf
							sed -i "/$cronname/d" /tmp/conf
							sed -i '/^$/d' /tmp/conf
							echo "$cronwords" >> /tmp/conf && crontab /tmp/conf
							rm -f /tmp/conf
							echo -----------------------------------------------
							echo -e "\033[31m定时任务已添加！！！\033[0m"
						fi
				fi			
			fi
		}
		echo -----------------------------------------------
		echo -e " 正在设置：\033[32m$cronname\033[0m定时任务"
		echo -e " 输入  1~7  对应\033[33m每周的指定某天\033[0m运行"
		echo -e " 输入   8   设为\033[33m每天\033[0m定时运行"
		echo -e " 输入 1,3,6 代表\033[36m指定每周1,3,6\033[0m运行(小写逗号分隔)"
		echo -e " 输入 a,b,c 代表\033[36m指定每周a,b,c\033[0m运行(1<=abc<=7)"
		echo -----------------------------------------------
		echo -e " 输入   9   \033[31m删除定时任务\033[0m"
		echo -e " 输入   0   返回上级菜单"
		echo -----------------------------------------------
		read -p "请输入对应数字 > " num
		if [ -z "$num" ]; then 
			errornum
		elif [ "$num" = 0 ]; then
			clashcron
		elif [ "$num" = 9 ]; then
			crontab -l > /tmp/conf && sed -i "/$cronname/d" /tmp/conf && crontab /tmp/conf
			rm -f /tmp/conf
			echo -----------------------------------------------
			echo -e "\033[31m定时任务：$cronname已删除！\033[0m"
		elif [ "$num" = 8 ]; then	
			week='*'
			week1=每天
			echo 已设为每天定时运行！
			setcrontab
		else
			week=$num	
			week1=每周$week
			echo 已设为每周 $num 运行！
			setcrontab
		fi
	}
	#定时任务菜单
	echo -----------------------------------------------
	echo  -e "\033[33m已添加的定时任务：\033[36m"
	crontab -l | grep -oE ' #.*' 
	echo -e "\033[0m"-----------------------------------------------
	echo -e " 1 设置\033[33m定时重启\033[0mclash服务"
	echo -e " 2 设置\033[31m定时停止\033[0mclash服务"
	echo -e " 3 设置\033[32m定时开启\033[0mclash服务"
	echo -e " 4 设置\033[33m定时更新\033[0m订阅并重启服务"
	echo -----------------------------------------------
	echo -e " 0 返回上级菜单" 
	read -p "请输入对应数字 > " num
	if [ -z "$num" ]; then 
		errornum
	elif [ "$num" = 0 ]; then
		subcstart
	elif [ "$num" = 1 ]; then
		cronname=重启clash服务
		cronset="supervisorctl restart clash"
		setcron
		clashcron
	elif [ "$num" = 2 ]; then
		cronname=停止clash服务
		cronset="supervisorctl stop clash"
		setcron
		clashcron
	elif [ "$num" = 3 ]; then
		cronname=开启clash服务
		cronset="supervisorctl start clash"
		setcron
		clashcron
	elif [ "$num" = 4 ]; then	
		cronname=更新订阅链接
		cronset="$subcPath updateyaml"
		setcron	
		clashcron
	else
		errornum
	fi
}

case "$1" in

updateyaml)	
		getyaml
		;;
esac

subcstart
