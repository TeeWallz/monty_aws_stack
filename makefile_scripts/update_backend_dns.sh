#!/bin/bash

source ./config_secrets.mk
source "./aws_utils.sh"

CLOUDFLARE_TOKEN=$(get_ssm_param "/monty/CLOUDFLARE_TOKEN")
CLOUDFLARE_ZONE_ID=$(get_ssm_param "/monty/CLOUDFLARE_ZONE_ID")

BACKEND_CLOUDFLARE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?name=api.howmanydayssincemontaguestreetbridgehasbeenhit.com" \
    -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')
MONTY_BACKEND_URL_BASE=$(make show-backend-base-url | sed -r 's/https:\/\/(.+)\/.+/\1/g')
# BACKEND_CLOUDFLARE_ID="${BACKEND_CLOUDFLARE_ID%\"}"
# BACKEND_CLOUDFLARE_ID="${BACKEND_CLOUDFLARE_ID#\"}"
# BACKEND_CLOUDFLARE_ID = $(shell make cloudflare-dns-list-api-data)



# echo $CLOUDFLARE_TOKEN
# echo $CLOUDFLARE_ZONE_ID
# echo $BACKEND_CLOUDFLARE_ID
echo $MONTY_BACKEND_URL_BASE



# exit 1

# echo $MONTY_BACKEND_URL_BASE

# if [ $MONTY_BACKEND_URL_BASE = null ]
#     echo "MONTY_BACKEND_URL_BASE is NULL. Quitting."
# then
#     exit 1
# fi

# echo $BACKEND_CLOUDFLARE_ID

# Has the zone been created already?
if [ $BACKEND_CLOUDFLARE_ID = null ]
then
    # If not, call the create API
    curl -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records" \
		-H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
		-H "Content-Type: application/json" \
		--data "{'type':'CNAME','name':'api.howmanydayssincemontaguestreetbridgehasbeenhit.com','content':'$MONTY_BACKEND_URL_BASE','ttl':3600,'priority':10,'proxied':true}"; echo 
else
    # Else, update
    base_json='{"type":"CNAME","name":"api.howmanydayssincemontaguestreetbridgehasbeenhit.com","content":"MONTY_BACKEND_URL_BASE","ttl":3600,"priority":10,"proxied":true}'
    json="${base_json/MONTY_BACKEND_URL_BASE/$MONTY_BACKEND_URL_BASE}"
    url="https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$BACKEND_CLOUDFLARE_ID"
    echo $json
    echo $url
    curl -X PUT $url \
		-H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
        -H "Content-Type: application/json" \
        --data $json ; echo 
fi
