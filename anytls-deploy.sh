#!/bin/bash

# ============================================================
#  xiaov2board + V2bX AnyTLS 一键部署脚本
#  专属配置：面板 www.1cny.cc / sing-box内核 / 自签证书
# ============================================================

# ---------- 颜色定义 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# ---------- 固定参数（你的面板信息）----------
API_HOST="https://www.1cny.cc"
API_KEY="PortMUl4OeUW02528c"
CERT_DOMAIN="ithome.com"
V2BX_CONFIG_DIR="/etc/V2bX"
V2BX_CONFIG_FILE="${V2BX_CONFIG_DIR}/config.json"

# ---------- 函数定义 ----------

print_banner() {
    echo ""
    echo -e "${CYAN}============================================================${PLAIN}"
    echo -e "${CYAN}   xiaov2board AnyTLS 一键部署脚本${PLAIN}"
    echo -e "${CYAN}   面板: ${API_HOST}${PLAIN}"
    echo -e "${CYAN}   协议: AnyTLS (sing-box)  证书: 自签 (${CERT_DOMAIN})${PLAIN}"
    echo -e "${CYAN}============================================================${PLAIN}"
    echo ""
}

print_ok() {
    echo -e "${GREEN}[OK] $1${PLAIN}"
}

print_err() {
    echo -e "${RED}[ERROR] $1${PLAIN}"
}

print_info() {
    echo -e "${YELLOW}[INFO] $1${PLAIN}"
}

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_err "请使用 root 用户运行此脚本"
        exit 1
    fi
}

# 检查系统类型
check_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        SYS_NAME="$ID"
    else
        print_err "无法识别操作系统"
        exit 1
    fi
    print_ok "系统检测: ${PRETTY_NAME}"
}

# 安装 V2bX（如果未安装）
install_v2bx() {
    if command -v V2bX &>/dev/null; then
        print_ok "V2bX 已安装，跳过安装步骤"
        # 获取版本
        V2bX version 2>/dev/null
    else
        print_info "正在安装 V2bX..."
        wget -N https://raw.githubusercontent.com/wyx2685/V2bX-script/master/install.sh -O /tmp/v2bx_install.sh
        if [[ $? -ne 0 ]]; then
            print_err "下载 V2bX 安装脚本失败，请检查网络"
            exit 1
        fi
        # 静默安装（跳过交互式配置向导）
        bash /tmp/v2bx_install.sh <<EOF
n
EOF
        rm -f /tmp/v2bx_install.sh

        if ! command -v V2bX &>/dev/null; then
            print_err "V2bX 安装失败"
            exit 1
        fi
        print_ok "V2bX 安装成功"
    fi
}

# 生成自签证书
generate_cert() {
    local CERT_FILE="${V2BX_CONFIG_DIR}/cert.pem"
    local KEY_FILE="${V2BX_CONFIG_DIR}/private.key"

    # 如果证书已存在且有效，跳过
    if [[ -f "$CERT_FILE" && -f "$KEY_FILE" ]]; then
        # 检查证书是否是我们生成的（CN 匹配）
        local EXISTING_CN
        EXISTING_CN=$(openssl x509 -in "$CERT_FILE" -noout -subject 2>/dev/null | grep -oP 'CN\s*=\s*\K[^/,]+')
        if [[ "$EXISTING_CN" == "$CERT_DOMAIN" ]]; then
            print_ok "自签证书已存在 (CN=${CERT_DOMAIN})，跳过生成"
            return 0
        fi
    fi

    print_info "正在生成自签证书 (CN=${CERT_DOMAIN})..."
    mkdir -p "$V2BX_CONFIG_DIR"

    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/CN=${CERT_DOMAIN}" \
        -days 36500 2>/dev/null

    if [[ $? -ne 0 ]]; then
        print_err "证书生成失败"
        exit 1
    fi

    chmod 600 "$KEY_FILE"
    chmod 644 "$CERT_FILE"
    print_ok "自签证书生成成功"
    print_info "  证书: ${CERT_FILE}"
    print_info "  密钥: ${KEY_FILE}"
}

# 生成 V2bX 配置文件
generate_config() {
    local NODE_ID=$1

    # 备份旧配置
    if [[ -f "$V2BX_CONFIG_FILE" ]]; then
        cp "$V2BX_CONFIG_FILE" "${V2BX_CONFIG_FILE}.bak.$(date +%Y%m%d%H%M%S)"
        print_info "旧配置已备份"
    fi

    cat > "$V2BX_CONFIG_FILE" << HEREDOC
{
    "Log": {
        "Level": "error",
        "Output": ""
    },
    "Cores": [
        {
            "Type": "sing",
            "Log": {
                "Level": "error",
                "Timestamp": true
            },
            "NTP": {
                "Enable": false,
                "Server": "time.apple.com",
                "ServerPort": 0
            },
            "OriginalPath": "${V2BX_CONFIG_DIR}/sing_origin.json"
        }
    ],
    "Nodes": [
        {
            "Core": "sing",
            "ApiHost": "${API_HOST}",
            "ApiKey": "${API_KEY}",
            "NodeID": ${NODE_ID},
            "NodeType": "anytls",
            "Timeout": 30,
            "ListenIP": "::",
            "SendIP": "0.0.0.0",
            "EnableProxyProtocol": false,
            "EnableDNS": true,
            "DomainStrategy": "ipv4_only",
            "DeviceOnlineMinTraffic": 200,
            "MinReportTraffic": 0,
            "TCPFastOpen": false,
            "SniffEnabled": true,
            "LimitConfig": {
                "EnableRealtime": false,
                "SpeedLimit": 0,
                "IPLimit": 0,
                "ConnLimit": 0,
                "EnableDynamicSpeedLimit": false
            },
            "CertConfig": {
                "CertMode": "file",
                "RejectUnknownSni": false,
                "CertDomain": "${CERT_DOMAIN}",
                "CertFile": "${V2BX_CONFIG_DIR}/cert.pem",
                "KeyFile": "${V2BX_CONFIG_DIR}/private.key"
            }
        }
    ]
}
HEREDOC

    if [[ $? -ne 0 ]]; then
        print_err "配置文件写入失败"
        exit 1
    fi
    print_ok "配置文件已生成: ${V2BX_CONFIG_FILE}"
}

# 生成多节点配置（支持多个节点ID）
generate_multi_config() {
    local NODE_IDS=("$@")
    local NODES_JSON=""

    for i in "${!NODE_IDS[@]}"; do
        local NID="${NODE_IDS[$i]}"
        if [[ $i -gt 0 ]]; then
            NODES_JSON+=","
        fi
        NODES_JSON+="
        {
            \"Core\": \"sing\",
            \"ApiHost\": \"${API_HOST}\",
            \"ApiKey\": \"${API_KEY}\",
            \"NodeID\": ${NID},
            \"NodeType\": \"anytls\",
            \"Timeout\": 30,
            \"ListenIP\": \"::\",
            \"SendIP\": \"0.0.0.0\",
            \"EnableProxyProtocol\": false,
            \"EnableDNS\": true,
            \"DomainStrategy\": \"ipv4_only\",
            \"DeviceOnlineMinTraffic\": 200,
            \"MinReportTraffic\": 0,
            \"TCPFastOpen\": false,
            \"SniffEnabled\": true,
            \"LimitConfig\": {
                \"EnableRealtime\": false,
                \"SpeedLimit\": 0,
                \"IPLimit\": 0,
                \"ConnLimit\": 0,
                \"EnableDynamicSpeedLimit\": false
            },
            \"CertConfig\": {
                \"CertMode\": \"file\",
                \"RejectUnknownSni\": false,
                \"CertDomain\": \"${CERT_DOMAIN}\",
                \"CertFile\": \"${V2BX_CONFIG_DIR}/cert.pem\",
                \"KeyFile\": \"${V2BX_CONFIG_DIR}/private.key\"
            }
        }"
    done

    # 备份旧配置
    if [[ -f "$V2BX_CONFIG_FILE" ]]; then
        cp "$V2BX_CONFIG_FILE" "${V2BX_CONFIG_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    fi

    cat > "$V2BX_CONFIG_FILE" << HEREDOC
{
    "Log": {
        "Level": "error",
        "Output": ""
    },
    "Cores": [
        {
            "Type": "sing",
            "Log": {
                "Level": "error",
                "Timestamp": true
            },
            "NTP": {
                "Enable": false,
                "Server": "time.apple.com",
                "ServerPort": 0
            },
            "OriginalPath": "${V2BX_CONFIG_DIR}/sing_origin.json"
        }
    ],
    "Nodes": [${NODES_JSON}
    ]
}
HEREDOC

    if [[ $? -ne 0 ]]; then
        print_err "配置文件写入失败"
        exit 1
    fi
    print_ok "多节点配置文件已生成 (${#NODE_IDS[@]} 个节点)"
}

# 配置防火墙
setup_firewall() {
    print_info "正在放行 443 端口..."

    # ufw
    if command -v ufw &>/dev/null; then
        ufw allow 443/tcp &>/dev/null
        print_ok "ufw 已放行 443/tcp"
    fi

    # firewalld
    if command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --add-port=443/tcp &>/dev/null
        firewall-cmd --reload &>/dev/null
        print_ok "firewalld 已放行 443/tcp"
    fi

    # iptables 兜底
    if command -v iptables &>/dev/null; then
        iptables -C INPUT -p tcp --dport 443 -j ACCEPT &>/dev/null 2>&1
        if [[ $? -ne 0 ]]; then
            iptables -I INPUT -p tcp --dport 443 -j ACCEPT &>/dev/null
        fi
    fi
}

# 启动并验证
start_and_verify() {
    print_info "正在重启 V2bX..."
    V2bX restart

    sleep 3

    # 检查进程是否在运行
    if pgrep -x "V2bX" &>/dev/null || systemctl is-active --quiet V2bX; then
        print_ok "V2bX 启动成功"
    else
        print_err "V2bX 启动失败，查看日志:"
        V2bX log 2>&1 | tail -20
        exit 1
    fi

    echo ""
    echo -e "${GREEN}============================================================${PLAIN}"
    echo -e "${GREEN}  部署完成！${PLAIN}"
    echo -e "${GREEN}============================================================${PLAIN}"
    echo -e "  面板地址:  ${CYAN}${API_HOST}${PLAIN}"
    echo -e "  节点ID:    ${CYAN}${DEPLOYED_IDS}${PLAIN}"
    echo -e "  协议类型:  ${CYAN}AnyTLS (sing-box)${PLAIN}"
    echo -e "  证书模式:  ${CYAN}自签 (${CERT_DOMAIN})${PLAIN}"
    echo -e "  监听端口:  ${CYAN}443${PLAIN}"
    echo ""
    echo -e "${YELLOW}  面板节点配置提醒:${PLAIN}"
    echo -e "  - 允许不安全:         ${RED}必须设为【是】${PLAIN}"
    echo -e "  - 服务器名称指示(SNI): ${CYAN}${CERT_DOMAIN}${PLAIN}"
    echo -e "  - 连接端口/服务端口:   ${CYAN}443${PLAIN}"
    echo ""
    echo -e "  查看日志: ${CYAN}V2bX log${PLAIN}"
    echo -e "  重启服务: ${CYAN}V2bX restart${PLAIN}"
    echo -e "${GREEN}============================================================${PLAIN}"
    echo ""
}

# 显示当前配置
show_config() {
    if [[ -f "$V2BX_CONFIG_FILE" ]]; then
        echo -e "${CYAN}当前配置文件内容:${PLAIN}"
        cat "$V2BX_CONFIG_FILE"
        echo ""
    else
        print_info "配置文件不存在"
    fi
}

# 卸载
uninstall() {
    echo -e "${RED}确定要卸载 V2bX 吗？(y/n)${PLAIN}"
    read -r confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        V2bX uninstall
        rm -f ${V2BX_CONFIG_DIR}/cert.pem ${V2BX_CONFIG_DIR}/private.key
        print_ok "卸载完成"
    fi
}

# ---------- 使用帮助 ----------
show_help() {
    echo ""
    echo -e "${CYAN}使用方法:${PLAIN}"
    echo ""
    echo -e "  ${GREEN}bash $0 <节点ID>${PLAIN}"
    echo -e "      部署单个 AnyTLS 节点"
    echo -e "      示例: bash $0 10"
    echo ""
    echo -e "  ${GREEN}bash $0 <ID1> <ID2> <ID3> ...${PLAIN}"
    echo -e "      同一台机器部署多个节点"
    echo -e "      示例: bash $0 10 11 12"
    echo ""
    echo -e "  ${GREEN}bash $0 config${PLAIN}"
    echo -e "      查看当前配置"
    echo ""
    echo -e "  ${GREEN}bash $0 uninstall${PLAIN}"
    echo -e "      卸载 V2bX"
    echo ""
    echo -e "  ${GREEN}bash $0 cert${PLAIN}"
    echo -e "      仅重新生成自签证书"
    echo ""
    echo -e "${YELLOW}面板节点添加提醒:${PLAIN}"
    echo -e "  1. 节点类型选 AnyTLS"
    echo -e "  2. 连接端口和服务端口填 443"
    echo -e "  3. 允许不安全选【是】"
    echo -e "  4. SNI 填 ${CERT_DOMAIN}"
    echo ""
}

# ---------- 主逻辑 ----------

print_banner
check_root

# 无参数 → 交互模式
if [[ $# -eq 0 ]]; then
    echo -e "${CYAN}请输入节点 ID（多个用空格分隔）:${PLAIN}"
    echo -e "${YELLOW}示例: 10 或 10 11 12${PLAIN}"
    read -r -p "> " INPUT_IDS

    if [[ -z "$INPUT_IDS" ]]; then
        show_help
        exit 0
    fi

    # 转为数组
    read -ra NODE_ARRAY <<< "$INPUT_IDS"

# 特殊命令
elif [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
elif [[ "$1" == "config" ]]; then
    show_config
    exit 0
elif [[ "$1" == "uninstall" ]]; then
    uninstall
    exit 0
elif [[ "$1" == "cert" ]]; then
    check_os
    # 强制重新生成
    rm -f "${V2BX_CONFIG_DIR}/cert.pem" "${V2BX_CONFIG_DIR}/private.key"
    generate_cert
    print_ok "证书已重新生成，请执行 V2bX restart"
    exit 0

# 命令行参数模式
else
    NODE_ARRAY=("$@")
fi

# 验证节点ID都是数字
for NID in "${NODE_ARRAY[@]}"; do
    if ! [[ "$NID" =~ ^[0-9]+$ ]]; then
        print_err "无效的节点ID: ${NID}（必须是纯数字）"
        exit 1
    fi
done

DEPLOYED_IDS="${NODE_ARRAY[*]}"
print_info "即将部署节点: ${DEPLOYED_IDS}"
echo ""

# 执行部署
check_os
install_v2bx
generate_cert

if [[ ${#NODE_ARRAY[@]} -eq 1 ]]; then
    generate_config "${NODE_ARRAY[0]}"
else
    generate_multi_config "${NODE_ARRAY[@]}"
fi

setup_firewall
start_and_verify
