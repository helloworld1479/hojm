#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin
export PATH

# 检查系统类型并安装 Docker
function install_docker(){
    echo "### 安装 Docker ###"
    DISTRO=$(lsb_release -is)

    if [[ "$DISTRO" == "Ubuntu" ]]; then
        echo "检测到 Ubuntu 系统，安装 Docker..."
        sudo apt-get update -y
        sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update -y
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    elif [[ "$DISTRO" == "Debian" ]]; then
        DEBIAN_VERSION=$(lsb_release -rs)

        # 对 Debian 13 使用特定的 Docker 安装步骤
        if [[ "$DEBIAN_VERSION" == "13" ]]; then
            echo "检测到 Debian 13 系统，使用特殊安装方法安装 Docker..."
            sudo apt update
            sudo apt install -y ca-certificates curl gnupg lsb-release

            # 安装 Docker GPG key 和源列表
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/debian/gpg | \
            sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
            https://download.docker.com/linux/debian bookworm stable" | \
            sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        else
            echo "检测到其他 Debian 版本，安装 Docker..."
            sudo apt update -y
            sudo apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
            curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
            sudo apt update -y
            sudo apt install -y docker-ce docker-ce-cli containerd.io
        fi
    else
        echo "不支持的系统类型: $DISTRO"
        exit 1
    fi

    # 启动并设置 Docker 服务为开机自启
    sudo systemctl enable --now docker
    echo "Docker 安装完成，服务已启动并设置为开机自启。"
}

# 安装 v2ray 后端相关服务
function v2ray(){
    echo "### 安装 v2ray 后端 ###"
    sysctl -p /etc/sysctl.conf

    # 安装 Docker
    install_docker

    # 启动 Docker 容器
    docker run --restart=always --name yitb -d \
    -v /etc/soga/:/etc/soga/ --network host \
    -e type=sspanel-uim \
    -e server_type=v2ray \
    -e node_id=198 \
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
    -e node_id=270 \
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
    -e type=xiaov2board \
    -e server_type=ss \
    -e node_id=45 \
    -e soga_key=updIcri6AetCowe89dlc70XQsk7C9lxs \
    -e api=webapi \
    -e webapi_url=https://888888881.xyz/ \
    -e webapi_key=PortMUl4OeUW02528c \
    -e proxy_protocol=true \
    -e tunnel_proxy_protocol=true \
    -e udp_proxy_protocol=true \
    -e redis_enable=true \
    -e redis_addr=ip.dlbtizi.net:1357 \
    -e redis_password=damai \
    -e redis_db=1 \
    -e conn_limit_expiry=60 \
    -e user_conn_limit=4 \
    vaxilu/soga:2.12.7

    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p

    echo "安装完成"
}

# 主菜单
function menu(){
    echo "### 安装 v2ray 后端 ###"
    echo "### 选择操作 ###"
    echo "请输入选项并按回车继续，ctrl+C退出"

    opt=0
    read opt
    if [ "$opt" = "1" ]; then
        v2ray
    else
        v2ray
    fi
}

menu
