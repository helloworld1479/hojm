#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
export PATH

function v2ray(){
    echo "###   东方木自用   ###"

    echo " "
    echo -e "\033[42;37m 请输入节点ID \033[0m 参考格式 42"
    read nodeid
    echo " "

    echo -e "\033[42;37m 节点ID \033[0m $nodeid"
    echo " "

    read -n 1
    apt-get update -y
    apt-get install curl -y
    bash <(curl -L -s  https://raw.githubusercontent.com/dongfangmu/v2ray-sspanel-v3-mod_Uim-plugin/master/install-release.sh) \
    --panelurl https://shuigengliu.com --panelkey dong --nodeid $nodeid \
    --downwithpanel 1 --speedtestrate 6 --paneltype 0 --usemysql 0
    systemctl start v2ray.service
    wget --no-check-certificate -O tcp.sh https://github.com/cx9208/Linux-NetSpeed/raw/master/tcp.sh && chmod +x tcp.sh && ./tcp.sh
    echo " "
    echo " "
    echo -e "\033[42;37m 安装完成 \033[0m"
}

