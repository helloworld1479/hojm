#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# ============================================================
# 固定配置（不需要每次修改）
# ============================================================
CFZONE_NAMES=("709900.xyz")
CFKEY="754562d8862d840a8eb6009745b79fc352610"
CFUSER="6733268@gmail.com"
CFTTL=1
WANIPSITE="http://ipv4.icanhazip.com"

SOGA_KEY="updIcri6AetCowe89dlc70XQsk7C9lxs"
WEBAPI_URL="https://888888881.xyz/"
WEBAPI_KEY="PortMUl4OeUW02528c"
REDIS_ADDR="ip.dlbtizi.net:1357"
REDIS_PASSWORD="damai"
REDIS_DB=1
SOGA_IMAGE="vaxilu/soga:2.12.7"

# ============================================================
# 颜色输出
# ============================================================
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════╗"
    echo "║        V2Board 节点一键部署工具           ║"
    echo "╚══════════════════════════════════════════╝"
    echo -e "${RESET}"
}

# ============================================================
# 交互式输入
# ============================================================
collect_inputs() {
    echo -e "${BOLD}请输入以下信息：${RESET}\n"

    # 节点注释（中文，用于 DNS 备注）
    while true; do
        read -rp "$(echo -e "${YELLOW}节点注释${RESET}（如：DJ-美国53）：") " INPUT_COMMENT
        [[ -n "${INPUT_COMMENT}" ]] && break
        echo -e "${RED}不能为空，请重新输入${RESET}"
    done

    # DNS 前缀
    while true; do
        read -rp "$(echo -e "${YELLOW}DNS 前缀${RESET}（如：uscc，最终解析为 前缀.709900.xyz）：") " INPUT_PREFIX
        [[ "${INPUT_PREFIX}" =~ ^[a-zA-Z0-9_-]+$ ]] && break
        echo -e "${RED}只能包含字母、数字、横线、下划线，请重新输入${RESET}"
    done

    # 节点 ID
    while true; do
        read -rp "$(echo -e "${YELLOW}节点 ID${RESET}（如：747）：") " INPUT_NODE_ID
        [[ "${INPUT_NODE_ID}" =~ ^[0-9]+$ ]] && break
        echo -e "${RED}节点 ID 必须是数字，请重新输入${RESET}"
    done

    # Docker 容器名（防止重名）
    DEFAULT_CONTAINER="soga_${INPUT_PREFIX}"
    read -rp "$(echo -e "${YELLOW}容器名称${RESET}（直接回车使用默认：${DEFAULT_CONTAINER}）：") " INPUT_CONTAINER
    INPUT_CONTAINER="${INPUT_CONTAINER:-${DEFAULT_CONTAINER}}"

    # 确认
    echo ""
    echo -e "${CYAN}╔══════════════ 确认信息 ══════════════╗${RESET}"
    echo -e "  节点注释  : ${BOLD}${INPUT_COMMENT}${RESET}"
    echo -e "  DNS 记录  : ${BOLD}${INPUT_PREFIX}.${CFZONE_NAMES[0]}${RESET}"
    echo -e "  节点 ID   : ${BOLD}${INPUT_NODE_ID}${RESET}"
    echo -e "  容器名称  : ${BOLD}${INPUT_CONTAINER}${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════╝${RESET}"
    echo ""
    read -rp "$(echo -e "确认无误？${GREEN}[y/N]${RESET} ")" CONFIRM
    if [[ ! "${CONFIRM}" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}已取消，重新输入...${RESET}\n"
        collect_inputs
    fi
}

# ============================================================
# 依赖检查
# ============================================================
check_and_install() {
    command -v "$1" &>/dev/null || {
        echo -e "${YELLOW}$1 未找到，正在安装...${RESET}"
        sudo apt-get install -y "$1"
    }
}

install_dependencies() {
    echo -e "\n${BOLD}### 检查依赖 ###${RESET}"
    for pkg in curl sudo unzip apt-transport-https gnupg lsb-release; do
        check_and_install "$pkg"
    done
}

# ============================================================
# WAN IP 获取
# ============================================================
get_wan_ip() {
    WAN_IP=$(curl -s "${WANIPSITE}")
    if [[ -z "${WAN_IP}" ]]; then
        echo -e "${RED}错误：无法获取 WAN IP${RESET}"; exit 1
    fi
    echo -e "当前 WAN IP：${GREEN}${WAN_IP}${RESET}"
}

# ============================================================
# Cloudflare DNS
# ============================================================
get_zone_id() {
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${1}" \
        -H "X-Auth-Email: ${CFUSER}" -H "X-Auth-Key: ${CFKEY}" \
        -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1
}

get_record_id() {
    local ZONE_ID="${1}" ZONE_NAME="${2}" REC_NAME="${3}"
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?name=${REC_NAME}.${ZONE_NAME}" \
        -H "X-Auth-Email: ${CFUSER}" -H "X-Auth-Key: ${CFKEY}" \
        -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1
}

update_or_create_dns() {
    local ZONE_NAME="${CFZONE_NAMES[0]}"
    local REC_NAME="${INPUT_PREFIX}"

    echo -e "\n${BOLD}### 更新 Cloudflare DNS ###${RESET}"
    get_wan_ip

    local ZONE_ID; ZONE_ID=$(get_zone_id "${ZONE_NAME}")
    local REC_ID;  REC_ID=$(get_record_id "${ZONE_ID}" "${ZONE_NAME}" "${REC_NAME}")
    local DATA="{\"type\":\"A\",\"name\":\"${REC_NAME}\",\"content\":\"${WAN_IP}\",\"ttl\":${CFTTL},\"proxied\":false,\"comment\":\"${INPUT_COMMENT}\"}"

    if [[ -n "${REC_ID}" ]]; then
        echo "记录已存在，正在更新..."
        RESP=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${REC_ID}" \
            -H "X-Auth-Email: ${CFUSER}" -H "X-Auth-Key: ${CFKEY}" \
            -H "Content-Type: application/json" --data "${DATA}")
    else
        echo "记录不存在，正在创建..."
        RESP=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
            -H "X-Auth-Email: ${CFUSER}" -H "X-Auth-Key: ${CFKEY}" \
            -H "Content-Type: application/json" --data "${DATA}")
    fi

    if [[ "${RESP}" == *'"success":true'* ]]; then
        echo -e "${GREEN}✓ DNS 记录已设置：${REC_NAME}.${ZONE_NAME} → ${WAN_IP}${RESET}"
    else
        echo -e "${RED}✗ DNS 操作失败，响应：${RESP}${RESET}"; exit 1
    fi
}

# ============================================================
# Docker 安装
# ============================================================
install_docker() {
    if command -v docker &>/dev/null; then
        echo -e "${GREEN}✓ Docker 已安装，跳过${RESET}"
        return
    fi

    echo -e "\n${BOLD}### 安装 Docker ###${RESET}"
    local DISTRO; DISTRO=$(lsb_release -is)
    local CODENAME; CODENAME=$(lsb_release -cs)
    local DEBIAN_VER; DEBIAN_VER=$(lsb_release -rs)

    sudo apt-get update -y
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    sudo install -m 0755 -d /etc/apt/keyrings

    if [[ "${DISTRO}" == "Ubuntu" ]]; then
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu ${CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    elif [[ "${DISTRO}" == "Debian" ]]; then
        # Debian 13 使用 bookworm 源
        [[ "${DEBIAN_VER}" == "13" ]] && CODENAME="bookworm"
        curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/debian ${CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    else
        echo -e "${RED}不支持的系统：${DISTRO}${RESET}"; exit 1
    fi

    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable --now docker
    echo -e "${GREEN}✓ Docker 安装完成${RESET}"
}

# ============================================================
# 启动 SOGA 容器
# ============================================================
start_soga() {
    echo -e "\n${BOLD}### 启动 SOGA 容器 ###${RESET}"

    # 若同名容器已存在则提示
    if docker ps -a --format '{{.Names}}' | grep -q "^${INPUT_CONTAINER}$"; then
        echo -e "${YELLOW}容器 ${INPUT_CONTAINER} 已存在，停止并删除旧容器...${RESET}"
        docker rm -f "${INPUT_CONTAINER}"
    fi

    docker run --restart=always --name "${INPUT_CONTAINER}" -d \
        -v /etc/soga/:/etc/soga/ --network host \
        -e type=xiaov2board \
        -e server_type=ss \
        -e node_id="${INPUT_NODE_ID}" \
        -e soga_key="${SOGA_KEY}" \
        -e api=webapi \
        -e webapi_url="${WEBAPI_URL}" \
        -e webapi_key="${WEBAPI_KEY}" \
        -e proxy_protocol=true \
        -e tunnel_proxy_protocol=true \
        -e udp_proxy_protocol=true \
        -e redis_enable=true \
        -e redis_addr="${REDIS_ADDR}" \
        -e redis_password="${REDIS_PASSWORD}" \
        -e redis_db="${REDIS_DB}" \
        -e conn_limit_expiry=60 \
        -e user_conn_limit=4 \
        "${SOGA_IMAGE}"

    echo -e "${GREEN}✓ 容器 ${INPUT_CONTAINER} 已启动${RESET}"
}

# ============================================================
# 开启 BBR
# ============================================================
enable_bbr() {
    echo -e "\n${BOLD}### 开启 BBR ###${RESET}"
    if ! grep -q "tcp_congestion_control=bbr" /etc/sysctl.conf; then
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    fi
    sysctl -p /etc/sysctl.conf
    echo -e "${GREEN}✓ BBR 已启用${RESET}"
}

# ============================================================
# 主流程
# ============================================================
main() {
    print_banner
    collect_inputs
    install_dependencies
    update_or_create_dns
    install_docker
    start_soga
    enable_bbr

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}║            🎉 部署完成！                  ║${RESET}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${RESET}"
    echo -e "  节点注释  : ${BOLD}${INPUT_COMMENT}${RESET}"
    echo -e "  DNS       : ${BOLD}${INPUT_PREFIX}.${CFZONE_NAMES[0]} → ${WAN_IP}${RESET}"
    echo -e "  节点 ID   : ${BOLD}${INPUT_NODE_ID}${RESET}"
    echo -e "  容器名称  : ${BOLD}${INPUT_CONTAINER}${RESET}"
    echo -e "\n  查看日志  : ${CYAN}docker logs -f ${INPUT_CONTAINER}${RESET}"
    echo -e "  查看状态  : ${CYAN}docker ps | grep ${INPUT_CONTAINER}${RESET}"
    echo ""
}

main
