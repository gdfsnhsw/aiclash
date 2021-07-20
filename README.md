# all in clash
使用moadns + subconverter + clash + docker 进行路由转发实现全局透明代理

## 食用方法
1. 开启混杂模式

    `ip link set ens192 promisc on`

1. docker创建网络,注意将网段改为你自己的

    `docker network create -d macvlan --subnet=192.168.88.0/24 --gateway=192.168.88.1 -o parent=ens192 _dMACvLan`

    *`_` 是为了提高 `_dMACvLan` 的优先级，可在多网络容器的中作为默认路由。

1. 运行容器

    ```yaml
    version: '3.2'
    services:
      aiclash:
        container_name: aiclash
        image: gdfsnhsw/aiclash:latest
        privileged: true
        logging:
          options:
            max-size: '10m'
            max-file: '3'
        restart: unless-stopped
        volumes:
          - ./clash:/aiclash/clash
          - ./subconverter:/aiclash/subconverter
          - ./mosdns:/aiclash/mosdns
        environment:
          - TZ=Asia/Shanghai
          - DNS_MODE=redir-host         # clash的dns模式，redir-host or fake-ip
          - CN_IP_ROUTE=true            # 是否绕过中国大陆ip，true or false
          - ROUTE_MODE=redir-tun        # 路由模式，redir-tun or tun or tproxy
          - GET_CONFIG=true             # 是否启用subconverter生成clash配置文件，true or false
          - UDP=true                    # 是否开启udp，true or false 
          - SCRIPT=true                 # 是否开启脚本模式，true or flase  
          - URL=https://~|trojan://~    # 订阅链接，合成一份，将多个订阅合成一份，使用 '|' 来分隔链接
        cap_add:
          - NET_ADMIN
          - SYS_ADMIN
        networks:
          dMACvLAN:
            ipv4_address: 192.168.88.2   # 容器ip
        dns:
          - 114.114.114.114

    networks:
      dMACvLAN:
        external:
          name: _dMACvLan
    ```

1. 将手机/电脑等客户端 网关设置为容器ip,如192.168.88.2 ,dns也设置成这个


## 附注 : 

1. 只要规则设置的对, 支持国内直连,国外走代理
1. 只在linux 测试过,win没试过, mac是不行, 第二步创建网络不行, docker自己的问题, 说不定以后哪天docker for mac支持了?

## 设置客户端
设置客户端（或设置路由器DHCP）默认网关及DNS服务器为容器IP:192.168.88.2

以openwrt为例，在`/etc/config/dhcp`中`config dhcp 'lan'`段加入：

```
  list dhcp_option '6,192.168.88.2'
  list dhcp_option '3,192.168.88.2'
```
## 关于IPv6 DNS
使用过程中发现，若启用了IPv6，某些客户端(Android)会自动将DNS服务器地址指向默认网关(路由器)的ipv6地址，导致客户端不走docker中的dns服务器。

解决方案是修改路由器中ipv6的`通告dns服务器`为容器ipv6地址。

以openwrt为例，在`/etc/config/dhcp`中`config dhcp 'lan'`段加入：
```
  list dns 'fe80::fe80'
```

## 关于宿主机出口
由于docker网络采用`macvlan`的`bridge`模式，宿主机虽然与容器在同一网段，但是相互之间是无法通信的，所以无法通过`aiclash`透明代理。

### 解决方案1

让宿主机直接走主路由，不经过代理网关：

```bash
ip route add default via 192.168.88.2 dev eth0 # 设置静态路由
echo "nameserver 192.168.88.2" > /etc/resolv.conf # 设置静态dns服务器
```

### 解决方案2

利用多个macvlan接口之间是互通的原理，新建一个macvlan虚拟接口：

* 临时配置网络（重启后失效）

   ```bash
   ip link add link eth0 mac0 type macvlan mode bridge # 在eth0接口下添加一个macvlan虚拟接口
   ip addr add 192.168.88.250/24 brd + dev mac0 # 为mac0 分配ip地址
   ip link set mac0 up
   ip route del default #删除默认路由
   ip route add default via 192.168.88.2 dev mac0 # 设置静态路由
   echo "nameserver 192.168.88.2" > /etc/resolv.conf # 设置静态dns服务器
   ```

* 永久配置网络（重启也能生效）

   * 使用 nmcli (推荐）

      `nmcli connection add type macvlan dev eth0 mode bridge ifname mac30 ipv4.route-metric 10 ipv6.route-metric 10 autoconnect yes save yes`

      如果想自定义 ip 及网关，可执行：

      `nmcli connection add type macvlan dev eth0 mode bridge ifname mac30 ipv4.route-metric 10 ipv6.route-metric 10 ipv4.method manual ip4 192.168.88.250/24 gw4 192.168.88.2 autoconnect yes save yes`

      注意：需使用更低的 `metric` 来提高 `default` 路由的优先级

      **另外，你可能需要修改 `dns`：**

      `nmcli con mod macvlan-mac30 ipv4.dns "192.168.88.2"`

      忽略 `eth0` 的 DHCP 自动获取的 dns:

      `nmcli con mod <eth0-connectionName> ipv4.ignore-auto-dns yes`

      **如果是 `ifupdown(eth0)`，先删除：**

      1. `/etc/network/interfaces` 仅保留以下内容：

        ```
        auto lo
        iface lo inet loopback
        ```

      2. `/etc/NetworkManager/NetworkManager.conf` 更改 **[ifupdown]** 条目中的 `managed` 值：
         ```
         [ifupdown]
         managed=false
         ```

   * 宿主机（Debian）修改网络配置：`vi /etc/network/interface`

      以下配置不支持网线热插拔，热插拔后需手动重启网络。可借用 `ifplugd` 解决（操作不详）

      将：
   
      ```
      auto eth0
      iface eth0 inet static
      address 192.168.88.250
      broadcast 192.168.88.255
      netmask 255.255.255.0
      gateway 192.168.88.2
      dns-nameservers 192.168.88.2
      ```
   
      修改为：
   
      ```
      auto eth0
      iface eth0 inet manual
   
      auto macvlan
      iface macvlan inet static
      metric 10
      address 192.168.88.250
      netmask 255.255.255.0
      gateway 192.168.88.2
      dns-nameservers 192.168.88.2
      	pre-up ip link add $IFACE link eth0 type macvlan mode bridge
      	post-down ip link del $IFACE link eth0 type macvlan mode bridge
      ```
   
      或
   
      ```
      auto eth0
      iface eth0 inet manual
   
      auto macvlan
      iface macvlan inet manual
      	#pre-up ip monitor link dev eth0 | grep -q 'state UP'
      	pre-up while ! ip link show eth0 | grep -q 'state UP'; do echo "waiting for eth0 is ready"; sleep 2; done
      	pre-up while ! ip route show | grep -q '^default'; do echo "waiting eth0 got required rules"; sleep 2; done
      	pre-up while ! ip route show | grep -q '192.168.88.0/24 dev eth0'; do echo "waiting eth0 got required rules"; sleep 2; done
      	pre-up ip link add $IFACE link eth0 type macvlan mode bridge
      	pre-up ip addr add 192.168.88.250/24 brd + dev $IFACE
      	up ip link set $IFACE up
      	#up udevadm trigger
      	post-up ip route del default
      	post-up ip route del 192.168.88.0/24 dev eth0
      	post-up ip route add default via 192.168.88.2 dev $IFACE
      	post-down ip link del dev $IFACE
      	down ifdown eth0
      	down ifup eth0
      ```
   
      修改完后重启网络  `systemctl restart networking` 或者重启系统查看效果。


**参考资料**

[docker_global_transparent_proxy](https://github.com/YouYII/docker_global_transparent_proxy)

配置文件

[https://lancellc.gitbook.io/clash/whats-new/clash-tun-mode/clash-tun-mode-2/setup-for-redir-host-mode](https://lancellc.gitbook.io/clash/whats-new/clash-tun-mode/clash-tun-mode-2/setup-for-redir-host-mode)

路由及防火墙设置

[kr328-clash-setup-scripts](https://github.com/h0cheung/kr328-clash-setup-scripts)

overturn DNS

[overturn + clash in docker as dns server and transparent proxy gateway](https://gist.github.com/killbus/69fdabdd1d8ae8f4030f4f96307ffa1b)

宿主机配置

https://github.com/fanyh123/tproxy-gateway
