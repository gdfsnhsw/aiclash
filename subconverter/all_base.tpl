{% if request.target == "clash" or request.target == "clashr" %}

# 系统参数
mixed-port: 7890            #集成端口，http与socks

redir-port: 7892            #透明代理端口，不能更改
tproxy-port: 7893
authentication:
  - "user:user"         #http与socks的账号跟密码，推荐使用
allow-lan: true
mode: Script
log-level: debug
ipv6: false
external-controller: 0.0.0.0:9090
external-ui: dashboard
secret: ""                  #dashboard面板的密码，同时也是tracing的密码
interface-name: eth0        #自行修改系统网卡名称
profile:
  store-selected: true      #策略组选择缓存开关，打开后可以保存策略组选择，重启不会回复默认
  tracing: false             #tracing开关，必须打开才能对接tracing


# 实验性功能
experimental:
  ignore-resolve-fail: true

# TUN设置
tun:
  enable: true
  stack: system # or gvisor
  dns-hijack:
    - tcp://8.8.8.8:53
    - tcp://8.8.4.4:53
    - udp://8.8.8.8:53
    - udp://8.8.4.4:53

hosts:
  # Firebase Cloud Messaging
  'mtalk.google.com': 108.177.125.188
  # Google Dl
  'dl.google.com': 180.163.151.161
  'dl.l.google.com': 180.163.151.161

# DNS设置  
dns:
  enable: true
  ipv6: false
  listen: 0.0.0.0:5352         # DNS监听端口！！！clash下，此处不能改，切记！！！！
  # DNS解析模式（redir-host # or fake-ip），这里重点解释一下：
  # redir-host为真实IP模式，需要设置nameserver（国内）和fallback（国外）两组DNS，当设备发起DNS请求，CLASH会同时向两组里面所有服务器发起请求，然后首先拿nameserver中最快返回的结果去匹配规则，使用GEOIP判断此IP的所属区域，如果属于国内（CN）或保留地址则直接响应给客户端，其他情况则把fallback中的结果响应给客户端
  # fake-ip则相反，当clash收到请求，会直接返回一个198.18.0.1/16的假IP给设备，同时 Clash 继续解析域名规则和 IP 规则，而且如果 Clash DNS 匹配到了域名规则、则不需要向上游 DNS 请求，Clash 已经可以直接将连接发给代理服务器，节省了 Clash DNS 向上游 DNS 请求解析
  default-nameserver:
    - 223.5.5.5
   # 理论上来说，fake-ip具有更好的响应速度跟抗污染能力（主要还得看规则）。由于灯塔提前分流了国内外流量，国内流量不经过clash，所以选择fake-ip可以得到更好的效果，当然，还是得看规则完不完整。有需要返回真实IP的可以选择redir-host，老实说两种DNS模式在实际体验中差别不大
{% if request.dns_mode == "redir-host" %}
  enhanced-mode: redir-host
{% else %}
  enhanced-mode: fake-ip
{% endif %} 
  fake-ip-range: 198.18.0.1/16   # ip范围
  use-hosts: true                # 开启
  fake-ip-filter:                # fake-ip白名单，对于有需要返回真实IP又想用fake-ip的，可参照以下格式把域名加进去
    # === LAN ===
    - '*.lan'
    - '*.localdomain'
    - '*.example'
    - '*.invalid'
    - '*.localhost'
    - '*.test'
    - '*.local'
    - '*.home.arpa'
    # === Linksys Wireless Router ===
    - '*.linksys.com'
    - '*.linksyssmartwifi.com'
    # === ASUS Router ===
    - '*.router.asus.com'
    # === Apple Software Update Service ===
    - 'swscan.apple.com'
    - 'mesu.apple.com'
    # === Windows 10 Connnect Detection ===
    - '*.msftconnecttest.com'
    - '*.msftncsi.com'
    - 'msftconnecttest.com'
    - 'msftncsi.com'
    # === Google ===
    - 'lens.l.google.com'
    - 'stun.l.google.com'
    ## Golang
    - 'proxy.golang.org'
    # === NTP Service ===
    - 'time.*.com'
    - 'time.*.gov'
    - 'time.*.edu.cn'
    - 'time.*.apple.com'
    - 'time1.*.com'
    - 'time2.*.com'
    - 'time3.*.com'
    - 'time4.*.com'
    - 'time5.*.com'
    - 'time6.*.com'
    - 'time7.*.com'
    - 'ntp.*.com'
    - 'ntp1.*.com'
    - 'ntp2.*.com'
    - 'ntp3.*.com'
    - 'ntp4.*.com'
    - 'ntp5.*.com'
    - 'ntp6.*.com'
    - 'ntp7.*.com'
    - '*.time.edu.cn'
    - '*.ntp.org.cn'
    - '+.pool.ntp.org'
    - 'time1.cloud.tencent.com'
    # === Game Service ===
    ## Nintendo Switch
    - '+.srv.nintendo.net'
    ## Sony PlayStation
    - '+.stun.playstation.net'
    ## Microsoft Xbox
    - 'xbox.*.microsoft.com'
    - 'xnotify.xboxlive.com'
    # === Other ===
    ## QQ Quick Login
    - 'localhost.ptlogin2.qq.com'
    - 'localhost.sec.qq.com'
    ## STUN Server
    - 'stun.*.*'
    - 'stun.*.*.*'
    - '+.stun.*.*'
    - '+.stun.*.*.*'
    - '+.stun.*.*.*.*'
  nameserver:                    # DNS服务器（国内），此处建议只填一个速度最快的DNS就可以了
    - 223.5.5.5

{% endif %}
