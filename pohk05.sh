#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
export PATH

function v2ray(){
    echo "###   v2ray后端   ###"
    echo "###     11      ###"
    echo "###     11      ###"

    echo " "
    echo -e "\033[41;33m 本功能仅支持Debian 9，请勿在其他系统中运行 \033[0m"
    echo " "
    echo "---------------------------------------------------------------------------"
    echo " "


    read -n 1
    echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf
    apt-get install sudo
    sudo apt-get update
    sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y
    systemctl start docker
    systemctl enable docker
    docker run --restart=always --name yitb -d \
    -v /etc/soga/:/etc/soga/ --network host \
    -e type=sspanel-uim \
    -e server_type=v2ray \
    -e node_id=335 \
    -e soga_key=uGzrFQjjdfTMmIsILudfeW1s5SDkGWw4 \
    -e api=webapi \
    -e webapi_url=https://dlbtizi.net/ \
    -e webapi_key=dong \
    -e proxy_protocol=true \
    -e force_vmess_aead=true \
    -e tunnel_proxy_protocol=true \
    -e redis_enable=true \
    -e redis_addr=ip.dlbtizi.net:1357 \
    -e redis_password=damai \
    -e redis_db=0 \
    -e conn_limit_expiry=60 \
    -e user_conn_limit=6 \
    vaxilu/soga:2.10.7
    
    docker run --restart=always --name yitba -d \
    -v /etc/soga/:/etc/soga/ --network host \
    -e type=sspanel-uim \
    -e server_type=v2ray \
    -e node_id=336 \
    -e soga_key=uGzrFQjjdfTMmIsILudfeW1s5SDkGWw4 \
    -e api=webapi \
    -e webapi_url=https://dlbtizi.net/ \
    -e webapi_key=dong \
    -e proxy_protocol=true \
    -e force_vmess_aead=true \
    -e tunnel_proxy_protocol=true \
    -e redis_enable=true \
    -e redis_addr=ip.dlbtizi.net:1357 \
    -e redis_password=damai \
    -e redis_db=0 \
    -e conn_limit_expiry=60 \
    -e user_conn_limit=6 \
    vaxilu/soga:2.10.7

    docker run --restart=always --name d1 -d \
    -v /etc/soga/:/etc/soga/ --network host \
    -e type=v2board \
    -e server_type=ss \
    -e node_id=29 \
    -e soga_key=updIcri6AetCowe89dlc70XQsk7C9lxs \
    -e api=webapi \
    -e webapi_url=https://888888881.xyz/ \
    -e webapi_key=iRMUl4OeUWRmUH8e \
    -e proxy_protocol=true \
    -e tunnel_proxy_protocol=true \
    -e udp_proxy_protocol=true \
    -e redis_enable=true \
    -e redis_addr=ip.dlbtizi.net:1357 \
    -e redis_password=damai \
    -e redis_db=1 \
    -e conn_limit_expiry=60 \
    -e user_conn_limit=4 \
    vaxilu/soga:2.10.7
    



    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    echo " "
    echo " "
    echo -e "\033[42;37m 安装完成 \033[0m"
}

function menu(){
    echo "###         东方木自用          ###"
    echo "###            usc1专用         ###"
    echo "###    Update: 2021-05-14      ###"
    echo ""

    echo "---------------------------------------------------------------------------"

    echo -e "\033[42;37m [1] \033[0m 安装v2ray后端"
    echo -e "\033[41;33m 请输入选项以继续，ctrl+C退出 \033[0m"

    opt=0
    read opt
    if [ "$opt"x = "1"x ]; then
        v2ray

    else
        v2ray
    fi
}

menu
