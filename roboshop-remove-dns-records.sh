#!/bin/bash

echo "🔥 Destroying instances and DNS records"

ZONE_ID="Z0022572U6LHZ3ASAGBB"
instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payment" "dispatch")

# --- DELETE Route53 Records ---
for instance in "${instances[@]}"; do

  if [[ "$instance" == "frontend" ]]; then
    RECORD_NAME="sharkdev.shop."
  else
    RECORD_NAME="${instance}.sharkdev.shop."
  fi

  echo "🧹 Checking DNS record: $RECORD_NAME"

  RECORD_JSON=$(aws route53 list-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --query "ResourceRecordSets[?Name == '${RECORD_NAME}'] | [0]" \
    --output json)

  if [[ "$RECORD_JSON" == "null" || -z "$RECORD_JSON" ]]; then
    echo "⚠️  Record not found or already deleted: $RECORD_NAME"
    continue
  fi

  echo "🗑 Deleting DNS record: $RECORD_NAME"

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Changes\": [
        {
          \"Action\": \"DELETE\",
          \"ResourceRecordSet\": $RECORD_JSON
        }
      ]
    }"

done

echo "✅ DNS record deletion completed."
