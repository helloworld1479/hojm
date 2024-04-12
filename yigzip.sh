#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
SPECIFIC_IP="211.91.66.241"  # 将这里的IP地址替换为您想要的特定IP

CFKEY="754562d8862d840a8eb6009745b79fc352610"
CFUSER="6733268@gmail.com"

CFZONE_NAMES=("potatoeswater.com" "dfnode.top" "potatoeswater.com" "dfnode.top" "potatoeswater.com" "dongfanghl.com" "dongfanghl.com" "dongfanghl.com" "dongfanghl.com")
CFRECORD_NAMES=("downca" "jjm" "download1" "jpcm" "download4" "down9pa" "down3a" "am" "ccu")

CFRECORD_TYPE=A
CFTTL=1
FORCE=false
WANIPSITE="http://ipv4.icanhazip.com"

if [ "$CFRECORD_TYPE" = "A" ]; then
  :
elif [ "$CFRECORD_TYPE" = "AAAA" ]; then
  WANIPSITE="http://ipv6.icanhazip.com"
else
  echo "$CFRECORD_TYPE specified is invalid, CFRECORD_TYPE can only be A(for IPv4)|AAAA(for IPv6)"
  exit 2
fi

for i in "${!CFZONE_NAMES[@]}"; do
    CFZONE_NAME="${CFZONE_NAMES[$i]}"
    CFRECORD_NAME="${CFRECORD_NAMES[$i]}"

    if [ "$CFRECORD_NAME" != "$CFZONE_NAME" ] && ! [ -z "${CFRECORD_NAME##*$CFZONE_NAME}" ]; then
        CFRECORD_NAME="$CFRECORD_NAME.$CFZONE_NAME"
        echo " => Hostname is not a FQDN, assuming $CFRECORD_NAME"
    fi

    WAN_IP=$SPECIFIC_IP
    WAN_IP_FILE=$HOME/.cf-wan_ip_$CFRECORD_NAME.txt
    if [ -f $WAN_IP_FILE ]; then
      OLD_WAN_IP=`cat $WAN_IP_FILE`
    else
      echo "No file, need IP"
      OLD_WAN_IP=""
    fi

    if [ "$WAN_IP" = "$OLD_WAN_IP" ] && [ "$FORCE" = false ]; then
      echo "WAN IP Unchanged, to update anyway use flag -f true"
      exit 0
    fi

    ID_FILE=$HOME/.cf-id_$CFRECORD_NAME.txt
    if [ -f $ID_FILE ] && [ $(wc -l $ID_FILE | cut -d " " -f 1) == 4 ] \
      && [ "$(sed -n '3,1p' "$ID_FILE")" == "$CFZONE_NAME" ] \
      && [ "$(sed -n '4,1p' "$ID_FILE")" == "$CFRECORD_NAME" ]; then
        CFZONE_ID=$(sed -n '1,1p' "$ID_FILE")
        CFRECORD_ID=$(sed -n '2,1p' "$ID_FILE")
    else
        echo "Updating zone_identifier & record_identifier"
        CFZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$CFZONE_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1 )
        CFRECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records?name=$CFRECORD_NAME" -H "X-Auth-Email: $CFUSER" -H "X-Auth-Key: $CFKEY" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*' | head -1 )
        echo "$CFZONE_ID" > $ID_FILE
        echo "$CFRECORD_ID" >> $ID_FILE
        echo "$CFZONE_NAME" >> $ID_FILE
        echo "$CFRECORD_NAME" >> $ID_FILE
    fi

    echo "Updating DNS to $WAN_IP"
    UPDATE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CFZONE_ID/dns_records/$CFRECORD_ID" \
    -H "X-Auth-Email: $CFUSER" \
    -H "X-Auth-Key: $CFKEY" \
    -H "Content-Type: application/json" \
    --data '{"type":"'$CFRECORD_TYPE'","name":"'$CFRECORD_NAME'","content":"'$WAN_IP'","ttl":'$CFTTL'}' \
    | grep -Po '(?<="success":)[^,]*')

    if [ $UPDATE = "true" ]; then
      echo "Updated succesfuly!"
      echo $WAN_IP > $WAN_IP_FILE
    else
      echo 'Something went wrong, check API calls!'
      exit 1
    fi
done

