#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Required Cloudflare API Key
CFKEY=754562d8862d840a8eb6009745b79fc352610

# Username, eg: user@example.com
CFUSER=6733268@gmail.com

# Zone name, eg: example.com
CFZONE_NAME=iosqq.top

# Default record type, A(IPv4)|AAAA(IPv6), default IPv4
CFRECORD_TYPE=A

# Default Cloudflare TTL for record, between 120 and 86400 seconds
CFTTL=1

# Ignore local file, update IP anyway
FORCE=false

# Site to retrieve WAN IP
WANIPSITE="http://ipv4.icanhazip.com"

# Check if the script received enough arguments
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 -h <CFRECORD_NAME> [-z <CFZONE_NAME>] [-t <CFRECORD_TYPE>] [-f <FORCE>]"
  exit 1
fi

# Parse command-line options
while getopts k:u:h:z:t:f: opts; do
  case ${opts} in
    k) CFKEY=${OPTARG} ;;
    u) CFUSER=${OPTARG} ;;
    h) CFRECORD_NAME=${OPTARG} ;;
    z) CFZONE_NAME=${OPTARG} ;;
    t) CFRECORD_TYPE=${OPTARG} ;;
    f) FORCE=${OPTARG} ;;
    *) echo "Invalid option: -${OPTARG}"; exit 1 ;;
  esac
done

# Validate mandatory parameters
if [ -z "${CFRECORD_NAME:-}" ]; then
  echo "Error: CFRECORD_NAME (-h) is required."
  exit 1
fi

if [ "$CFRECORD_TYPE" = "A" ]; then
  :
elif [ "$CFRECORD_TYPE" = "AAAA" ]; then
  WANIPSITE="http://ipv6.icanhazip.com"
else
  echo "Error: Invalid CFRECORD_TYPE. Use 'A' (IPv4) or 'AAAA' (IPv6)."
  exit 1
fi

# Get current and old WAN IP
WAN_IP=$(curl -s ${WANIPSITE})
WAN_IP_FILE="$HOME/.cf-wan_ip_$CFRECORD_NAME.txt"
OLD_WAN_IP=$(cat "$WAN_IP_FILE" 2>/dev/null || echo "")

if [ "$WAN_IP" = "$OLD_WAN_IP" ] && [ "$FORCE" = false ]; then
  echo "WAN IP unchanged. Use -f true to force update."
  exit 0
fi

# Retrieve zone and record identifiers
ID_FILE="$HOME/.cf-id_$CFRECORD_NAME.txt"
if [ -f "$ID_FILE" ] && grep -q "$CFZONE_NAME" "$ID_FILE"; then
  CFZONE_ID=$(sed -n '1p' "$ID_FILE")
  CFRECORD_ID=$(sed -n '2p' "$ID_FILE")
else
  echo "Fetching zone and record IDs..."
  CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" \
    -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" \
    | grep -Po '(?<="id":")[^"]*' | head -1)
  CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" \
    -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" \
    | grep -Po '(?<="id":")[^"]*' | head -1)
  echo -e "$CFZONE_ID\n$CFRECORD_ID\n$CFZONE_NAME\n$CFRECORD_NAME" > "$ID_FILE"
fi

# Update Cloudflare DNS record
echo "Updating DNS record for $CFRECORD_NAME to $WAN_IP..."
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
  -H "X-Auth-Email: $CFUSER" \
  -H "X-Auth-Key: $CFKEY" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"$CFRECORD_TYPE\",\"name\":\"$CFRECORD_NAME\",\"content\":\"$WAN_IP\",\"ttl\":$CFTTL}")

if echo "$RESPONSE" | grep -q '"success":true'; then
  echo "DNS record updated successfully."
  echo "$WAN_IP" > "$WAN_IP_FILE"
else
  echo "Error updating DNS record. Response: $RESPONSE"
  exit 1
fi
