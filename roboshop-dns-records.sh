#!/bin/bash

ZONE_ID="Z0022572U6LHZ3ASAGBB"

# Safely get instance ID and its service tag
instances=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*latest" \
  --query "Reservations[].Instances[].[InstanceId, Tags[?Key=='service'] | [0].Value]" \
  --output text)

# Process each instance
while read -r INSTANCE_ID SERVICE_TAG; do
  # Skip if SERVICE_TAG is empty
  if [[ -z "$SERVICE_TAG" || "$SERVICE_TAG" == "None" ]]; then
    echo "⚠️  Skipping instance $INSTANCE_ID due to missing service tag"
    continue
  fi

  echo "🔄 Processing $SERVICE_TAG ($INSTANCE_ID)"

  # Get IPs
  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

  PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)

  # Decide IP
  if [[ "$SERVICE_TAG" == "frontend" ]]; then
    SELECTED_IP="$PUBLIC_IP"
    DNS_NAME="sharkdev.shop"
  else
    SELECTED_IP="$PRIVATE_IP"
    DNS_NAME="${SERVICE_TAG}.sharkdev.shop"
  fi

  # Check IP validity
  if [[ -z "$SELECTED_IP" || "$SELECTED_IP" == "None" ]]; then
    echo "⚠️  Skipping $SERVICE_TAG due to missing IP"
    continue
  fi

  # Create or update DNS record
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

done <<< "$instances"

echo "✅ All DNS records updated successfully."
