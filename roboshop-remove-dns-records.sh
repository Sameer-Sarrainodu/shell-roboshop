#!/bin/bash

ZONE_ID="Z0022572U6LHZ3ASAGBB"
services=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payment" "dispatch")

for service in "${services[@]}"; do
    RECORD_NAME="${service}.sharkdev.shop."

    echo "Checking and deleting: $RECORD_NAME"

    # Get the current record set (only first match)
    RECORD_JSON=$(aws route53 list-resource-record-sets \
      --hosted-zone-id "$ZONE_ID" \
      --query "ResourceRecordSets[?Name == '${RECORD_NAME}'] | [0]" \
      --output json)

    # Skip if empty
    if [[ "$RECORD_JSON" == "null" ]]; then
      echo "Record $RECORD_NAME not found or already deleted."
      continue
    fi

    echo "Deleting DNS record: $RECORD_NAME"

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