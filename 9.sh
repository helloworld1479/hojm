#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Config
CFKEY="754562d8862d840a8eb6009745b79fc352610"
CFUSER="6733268@gmail.com"
CFZONE_NAMES=("iosqq.top" "888888881.xyz")
CFRECORD_NAMES=("sgp1" "sg")
CFTTL=1
FORCE=false
WANIPSITE="http://ipv4.icanhazip.com"

# Function to update DNS record
update_dns_record() {
    local ZONE_NAME="${1}"
    local RECORD_NAME="${2}"

    # Get zone_identifier & record_identifier
    CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${ZONE_NAME}" -H "X-Auth-Email: ${CFUSER}" -H "X-Auth-Key: ${CFKEY}" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
    CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CFZONE_ID}/dns_records?name=${RECORD_NAME}.${ZONE_NAME}" -H "X-Auth-Email: ${CFUSER}" -H "X-Auth-Key: ${CFKEY}" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )

    # Update DNS record
    RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CFZONE_ID}/dns_records/${CFRECORD_ID}" \
      -H "X-Auth-Email: ${CFUSER}" \
      -H "X-Auth-Key: ${CFKEY}" \
      -H "Content-Type: application/json" \
      --data "{\"id\":\"${CFZONE_ID}\",\"type\":\"A\",\"name\":\"${RECORD_NAME}\",\"content\":\"${WAN_IP}\",\"ttl\":${CFTTL}}")

    # Check if the update was successful
    if [[ "${RESPONSE}" != *'"success":false'* ]]; then
        echo "Updated DNS for ${RECORD_NAME}.${ZONE_NAME} to ${WAN_IP}"
    else
        echo "Failed to update DNS for ${RECORD_NAME}.${ZONE_NAME}"
        echo "Response: ${RESPONSE}"
    fi
}

# Get current WAN IP
WAN_IP=$(curl -s ${WANIPSITE})

# Loop through the domain records and update each one
for i in "${!CFZONE_NAMES[@]}"; do
    ZONE_NAME="${CFZONE_NAMES[$i]}"
    RECORD_NAME="${CFRECORD_NAMES[$i]}"
    update_dns_record "${ZONE_NAME}" "${RECORD_NAME}"
done
