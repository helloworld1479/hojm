#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# 默认配置值
CFKEY="754562d8862d840a8eb6009745b79fc352610"
CFUSER="6733268@gmail.com"
CFZONE_NAME="iosqq.top"
CFRECORD_NAME="default_record_name"  # 默认记录名称，可以通过命令行参数更改
CFRECORD_TYPE="A"
CFTTL=1
FORCE=false
WANIPSITE="http://ipv4.icanhazip.com"

# 从命令行覆盖默认记录名称
while getopts "h:" opt; do
  case ${opt} in
    h)
      CFRECORD_NAME=${OPTARG}
      ;;
    \?)
      echo "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
  esac
done

# 获取当前和旧的WAN IP
WAN_IP=$(curl -s ${WANIPSITE})
WAN_IP_FILE="$HOME/.cf-wan_ip_$CFRECORD_NAME.txt"
if [ -f "$WAN_IP_FILE" ]; then
  OLD_WAN_IP=$(cat $WAN_IP_FILE)
else
  OLD_WAN_IP=""
fi

# 强制更新或IP有变化时更新Cloudflare记录
if [ "$WAN_IP" != "$OLD_WAN_IP" ] || [ "$FORCE" = true ]; then
  # 更新区域标识符和记录标识符
  echo "Updating zone_identifier & record_identifier"
  CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)
  CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1)

  # 更新DNS记录
  echo "Updating DNS for $CFRECORD_NAME to $WAN_IP"
  RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
    -H "X-Auth-Email: $CFUSER" \
    -H "X-Auth-Key: $CFKEY" \
    -H "Content-Type: application/json" \
    --data "{\"id\":\"$CFZONE_ID\",\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$WAN_IP\", \"ttl\":$CFTTL}")

  if [[ "$RESPONSE" == *'"success":true'* ]]; then
    echo "Updated successfully! $CFRECORD_NAME now points to $WAN_IP"
    echo $WAN_IP > $WAN_IP_FILE
  else
    echo "Something went wrong :("
    echo "Response: $RESPONSE"
    exit 1
  fi
else
  echo "WAN IP unchanged, to update anyway use -f true"
fi
