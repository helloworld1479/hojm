#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Default configuration values
CFKEY=754562d8862d840a8eb6009745b79fc352610
CFUSER="6733268@gmail.com"
CFZONE_NAME="iosqq.top"
CFRECORD_NAME="wyq"  # Default value
CFRECORD_TYPE=A
CFTTL=1
FORCE=false
WANIPSITE="http://ipv4.icanhazip.com"

# Override defaults from command line arguments
while getopts k:u:z:h:t:l:f: opts; do
  case ${opts} in
    k) CFKEY=${OPTARG} ;;
    u) CFUSER=${OPTARG} ;;
    z) CFZONE_NAME=${OPTARG} ;;
    h) CFRECORD_NAME=${OPTARG} ;;
    t) CFRECORD_TYPE=${OPTARG} ;;
    l) CFTTL=${OPTARG} ;;
    f) FORCE=${OPTARG} ;;
  esac
done

# Function to check and update WAN IP
update_wan_ip() {
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
}

# Main script logic
main() {
  # Get current and old WAN IP
  WAN_IP=$(curl -s ${WANIPSITE})
  WAN_IP_FILE="$HOME/.cf-wan_ip_$CFRECORD_NAME.txt"
  if [ -f $WAN_IP_FILE ]; then
    OLD_WAN_IP=$(cat $WAN_IP_FILE)
  else
    OLD_WAN_IP=""
  fi

  # If WAN IP has changed or force flag is true, update Cloudflare
  if [ "$WAN_IP" != "$OLD_WAN_IP" ] || [ "$FORCE" = true ]; then
    update_wan_ip
  else
    echo "WAN IP unchanged, to update anyway use -f true"
  fi
}

# Run the script
main
