#!/usr/bin/env bash
#
# Cloudflare DDNS 通用脚本（多账号版）
# 功能：每分钟检测 VPS 公网 IP 是否变化，变化则自动更新多个 Cloudflare 账号的 DNS 记录
#

set -o errexit
set -o nounset
set -o pipefail

# ============================================================
#  通用配置
# ============================================================

CFTTL=1                                       # TTL（1 = 自动）
PROXIED=false                                 # 是否开启 CF 小云朵代理（true/false）

# 获取公网 IP 的地址（备用多个，防止单点故障）
WANIP_URLS=(
    "https://ip.sb"
    "https://api.ip.sb/ip"
    "https://4.ipw.cn"
    "https://myip.ipip.net/ip"
    "https://ipv4.icanhazip.com"
    "https://api.ipify.org"
    "https://ifconfig.me/ip"
)

# IP 缓存文件路径
IP_CACHE="/tmp/.cf_ddns_cached_ip"

# 日志文件路径
LOG_FILE="/var/log/cf-ddns.log"

# ============================================================
#  账号 1 配置
# ============================================================

ACCOUNT1_CFKEY="754562d8862d840a8eb6009745b79fc352610"
ACCOUNT1_CFUSER="6733268@gmail.com"
ACCOUNT1_ZONES=("lieningzhuyi.com" "709900.xyz")
ACCOUNT1_RECORDS=("*.may" "twdt")
ACCOUNT1_COMMENTS=("DJ-台湾动态L3" "DJ-台湾动态L3")

# ============================================================
#  账号 2 配置
# ============================================================

ACCOUNT2_CFKEY="ab0d638bb9645a0aa5f134ec9988734d741ab"
ACCOUNT2_CFUSER="phungduyla@gmail.com"
ACCOUNT2_ZONES=("345686.cc" "345686.cc")
ACCOUNT2_RECORDS=("ls01" "ls001")
ACCOUNT2_COMMENTS=("DDNS自动更新" "DDNS自动更新")

# ============================================================
#  以下内容一般不需要修改
# ============================================================

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

get_wan_ip() {
    local ip="" raw=""
    for url in "${WANIP_URLS[@]}"; do
        raw=$(curl -4 -s --max-time 5 "$url" 2>/dev/null) || continue
        ip=$(echo "$raw" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)
        if [[ -n "$ip" ]]; then
            echo "$ip"
            return 0
        fi
    done
    return 1
}

get_zone_id() {
    local zone_name="$1" cfuser="$2" cfkey="$3"
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${zone_name}" \
        -H "X-Auth-Email: ${cfuser}" \
        -H "X-Auth-Key: ${cfkey}" \
        -H "Content-Type: application/json" \
        | grep -Po '(?<="id":")[^"]*' | head -1
}

get_record_id() {
    local zone_id="$1" fqdn="$2" cfuser="$3" cfkey="$4"
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=${fqdn}&type=A" \
        -H "X-Auth-Email: ${cfuser}" \
        -H "X-Auth-Key: ${cfkey}" \
        -H "Content-Type: application/json" \
        | grep -Po '(?<="id":")[^"]*' | head -1
}

get_record_ip() {
    local zone_id="$1" fqdn="$2" cfuser="$3" cfkey="$4"
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=${fqdn}&type=A" \
        -H "X-Auth-Email: ${cfuser}" \
        -H "X-Auth-Key: ${cfkey}" \
        -H "Content-Type: application/json" \
        | grep -Po '(?<="content":")[^"]*' | head -1
}

create_record() {
    local zone_id="$1" fqdn="$2" ip="$3" comment="$4" cfuser="$5" cfkey="$6"
    local resp
    resp=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
        -H "X-Auth-Email: ${cfuser}" \
        -H "X-Auth-Key: ${cfkey}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"${fqdn}\",\"content\":\"${ip}\",\"ttl\":${CFTTL},\"proxied\":${PROXIED},\"comment\":\"${comment}\"}")

    if [[ "$resp" == *'"success":true'* ]]; then
        log "✅ 创建成功: ${fqdn} -> ${ip}"
    else
        log "❌ 创建失败: ${fqdn}"
        log "   响应: ${resp}"
    fi
}

update_record() {
    local zone_id="$1" record_id="$2" fqdn="$3" ip="$4" comment="$5" cfuser="$6" cfkey="$7"
    local resp
    resp=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${record_id}" \
        -H "X-Auth-Email: ${cfuser}" \
        -H "X-Auth-Key: ${cfkey}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"${fqdn}\",\"content\":\"${ip}\",\"ttl\":${CFTTL},\"proxied\":${PROXIED},\"comment\":\"${comment}\"}")

    if [[ "$resp" == *'"success":true'* ]]; then
        log "✅ 更新成功: ${fqdn} -> ${ip}"
    else
        log "❌ 更新失败: ${fqdn}"
        log "   响应: ${resp}"
    fi
}

# 处理单个账号下的所有域名记录
process_account() {
    local cfuser="$1" cfkey="$2" current_ip="$3"
    shift 3
    # 剩余参数格式：zone1 record1 comment1 zone2 record2 comment2 ...
    local args=("$@")
    local count=$(( ${#args[@]} / 3 ))

    log "====== 账号: ${cfuser} ======"

    for (( i=0; i<count; i++ )); do
        local zone_name="${args[$((i*3))]}"
        local record_name="${args[$((i*3+1))]}"
        local comment="${args[$((i*3+2))]}"
        local fqdn="${record_name}.${zone_name}"

        log "--- 处理: ${fqdn} ---"

        # 获取 Zone ID
        local zone_id
        zone_id=$(get_zone_id "$zone_name" "$cfuser" "$cfkey")
        if [[ -z "$zone_id" ]]; then
            log "❌ 找不到域名 ${zone_name} 的 Zone ID，请检查 API Key 和域名"
            continue
        fi

        # 获取 Record ID
        local record_id
        record_id=$(get_record_id "$zone_id" "$fqdn" "$cfuser" "$cfkey")

        if [[ -z "$record_id" ]]; then
            log "📝 记录不存在，正在创建..."
            create_record "$zone_id" "$fqdn" "$current_ip" "$comment" "$cfuser" "$cfkey"
        else
            local cf_ip
            cf_ip=$(get_record_ip "$zone_id" "$fqdn" "$cfuser" "$cfkey")
            if [[ "$cf_ip" == "$current_ip" ]]; then
                log "⏭️  ${fqdn} 已经是 ${current_ip}，无需更新"
            else
                log "📝 正在更新: ${cf_ip} -> ${current_ip}"
                update_record "$zone_id" "$record_id" "$fqdn" "$current_ip" "$comment" "$cfuser" "$cfkey"
            fi
        fi
    done
}

# ============================================================
#  主逻辑
# ============================================================
main() {
    # 1. 获取当前公网 IP
    local current_ip
    current_ip=$(get_wan_ip) || {
        log "⚠️  无法获取公网 IP，跳过本次检测"
        exit 0
    }

    # 2. 读取缓存 IP，对比是否有变化
    local cached_ip=""
    if [[ -f "$IP_CACHE" ]]; then
        cached_ip=$(cat "$IP_CACHE" 2>/dev/null || true)
    fi

    if [[ "$current_ip" == "$cached_ip" ]]; then
        exit 0
    fi

    # 3. IP 有变化（或首次运行），更新所有记录
    if [[ -n "$cached_ip" ]]; then
        log "🔄 检测到 IP 变化: ${cached_ip} -> ${current_ip}"
    else
        log "🚀 首次运行，当前 IP: ${current_ip}"
    fi

    # 构建参数列表并处理账号 1
    local account1_args=()
    for i in "${!ACCOUNT1_ZONES[@]}"; do
        account1_args+=("${ACCOUNT1_ZONES[$i]}" "${ACCOUNT1_RECORDS[$i]}" "${ACCOUNT1_COMMENTS[$i]}")
    done
    process_account "$ACCOUNT1_CFUSER" "$ACCOUNT1_CFKEY" "$current_ip" "${account1_args[@]}"

    # 构建参数列表并处理账号 2
    local account2_args=()
    for i in "${!ACCOUNT2_ZONES[@]}"; do
        account2_args+=("${ACCOUNT2_ZONES[$i]}" "${ACCOUNT2_RECORDS[$i]}" "${ACCOUNT2_COMMENTS[$i]}")
    done
    process_account "$ACCOUNT2_CFUSER" "$ACCOUNT2_CFKEY" "$current_ip" "${account2_args[@]}"

    # 4. 更新缓存
    echo "$current_ip" > "$IP_CACHE"

    log "✅ 本次 DDNS 检测完成（共 2 个账号）"
}

main "$@"
