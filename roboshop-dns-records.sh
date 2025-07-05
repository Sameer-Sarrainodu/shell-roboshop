#!/bin/bash

ZONE_ID="Z0022572U6LHZ3ASAGBB"

# Get instances and their tags (only if service tag exists)
instances=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*latest" \
  --query "Reservations[].Instances[].[InstanceId, Tags]" \
  --output json)

# Loop through JSON manually using jq
echo "$instances" | jq -c '.[]' | while read -r instance; do
  INSTANCE_ID=$(echo "$instance" | jq -r '.[0]')
  TAGS=$(echo "$instance" | jq -r '.[1]')

  SERVICE_TAG=$(echo "$TAGS" | jq -r '.[] | select(.Key=="service") | .Value' 2>/dev/null)

  if [[ -z "$SERVICE_TAG" || "$SERVICE_TAG" == "null" ]]; then
    echo "⚠️  Skipping instance $INSTANCE_ID due to missing service tag"
    continue
  fi

  echo "🔄 Processing $SERVICE_TAG ($INSTANCE_ID)"

  # Get public and private IP
  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

  PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)

  # Choose IP based on service
  if [[ "$SERVICE_TAG" == "frontend" ]]; then
    SELECTED_IP="$PUBLIC_IP"
    DNS_NAME="sharkdev.shop"
  else
    SELECTED_IP="$PRIVATE_IP"
    DNS_NAME="${SERVICE_TAG}.sharkdev.shop"
  fi

  if [[ -z "$SELECTED_IP" || "$SELECTED_IP" == "None" ]]; then
    echo "⚠️  Skipping $SERVICE_TAG due to missing IP"
    continue
  fi

  # Update DNS
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"$DNS_NAME\",
          \"Type\": \"A\",
          \"TTL\": 5,
          \"ResourceRecords\": [{\"Value\": \"$SELECTED_IP\"}]
        }
      }]
    }"

  echo "✅ DNS record set for $DNS_NAME → $SELECTED_IP"
done

echo "✅ All DNS records updated successfully."
