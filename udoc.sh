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