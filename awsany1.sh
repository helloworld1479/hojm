#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# ============== 配置 ==============
COMMENT="DJ-波兰"
CFZONE_NAMES=("345686.cc" "345686.cc")
CFRECORD_NAMES=("ls01" "ls001")
CFKEY="ab0d638bb9645a0aa5f134ec9988734d741ab"
CFUSER="phungduyla@gmail.com"
CFTTL=1
WANIPSITE="http://ipv4.icanhazip.com"

# ============== 函数 ==============

# 获取公网 IP
get_wan_ip() {
    WAN_IP=$(curl -s ${WANIPSITE})
    if [[ -z "${WAN_IP}" ]]; then
        echo "Error: 无法获取公网 IP"
        exit 1
    fi
    echo "当前公网 IP: ${WAN_IP}"
}

# 获取 Zone ID
get_zone_id() {
    local ZONE_NAME="${1}"
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${ZONE_NAME}" \
      -H "X-Auth-Email: ${CFUSER}" \
      -H "X-Auth-Key: ${CFKEY}" \
      -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1
}

# 获取 Record ID（不存在则返回空）
get_record_id() {
    local ZONE_ID="${1}"
    local FQDN="${2}"
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?name=${FQDN}" \
      -H "X-Auth-Email: ${CFUSER}" \
      -H "X-Auth-Key: ${CFKEY}" \
      -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1
}

# 创建 DNS 记录
create_dns_record() {
    local ZONE_ID="${1}"
    local RECORD_NAME="${2}"
    local FQDN="${3}"

    RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
      -H "X-Auth-Email: ${CFUSER}" \
      -H "X-Auth-Key: ${CFKEY}" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}\",\"content\":\"${WAN_IP}\",\"ttl\":${CFTTL},\"proxied\":false,\"comment\":\"${COMMENT}\"}")

    if [[ "${RESPONSE}" == *'"success":true'* ]]; then
        echo "✅ 创建成功: ${FQDN} -> ${WAN_IP}"
    else
        echo "❌ 创建失败: ${FQDN}"
        echo "Response: ${RESPONSE}"
    fi
}

# 更新 DNS 记录
update_dns_record() {
    local ZONE_ID="${1}"
    local RECORD_ID="${2}"
    local RECORD_NAME="${3}"
    local FQDN="${4}"

    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
      -H "X-Auth-Email: ${CFUSER}" \
      -H "X-Auth-Key: ${CFKEY}" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"${RECORD_NAME}\",\"content\":\"${WAN_IP}\",\"ttl\":${CFTTL},\"proxied\":false,\"comment\":\"${COMMENT}\"}")

    if [[ "${RESPONSE}" != *'"success":false'* ]]; then
        echo "✅ 更新成功: ${FQDN} -> ${WAN_IP}"
    else
        echo "❌ 更新失败: ${FQDN}"
        echo "Response: ${RESPONSE}"
    fi
}

# ============== 主流程 ==============
get_wan_ip

for i in "${!CFZONE_NAMES[@]}"; do
    ZONE_NAME="${CFZONE_NAMES[$i]}"
    RECORD_NAME="${CFRECORD_NAMES[$i]}"
    FQDN="${RECORD_NAME}.${ZONE_NAME}"

    echo "--- 处理 ${FQDN} ---"

    ZONE_ID=$(get_zone_id "${ZONE_NAME}")
    if [[ -z "${ZONE_ID}" ]]; then
        echo "❌ 无法获取 ${ZONE_NAME} 的 Zone ID，跳过"
        continue
    fi

    RECORD_ID=$(get_record_id "${ZONE_ID}" "${FQDN}")

    if [[ -n "${RECORD_ID}" ]]; then
        echo "记录已存在，更新中..."
        update_dns_record "${ZONE_ID}" "${RECORD_ID}" "${RECORD_NAME}" "${FQDN}"
    else
        echo "记录不存在，创建中..."
        create_dns_record "${ZONE_ID}" "${RECORD_NAME}" "${FQDN}"
    fi
done

echo "DNS 解析更新完成"
