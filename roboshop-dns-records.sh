#!/bin/bash

ZONE_ID="Z0022572U6LHZ3ASAGBB"

# Fetch running instances tagged with *latest and having 'service' tag
instances=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*latest" \
  --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='service']|[0].Value]" \
  --output text)

# Loop through each instance line
while read -r INSTANCE_ID SERVICE_TAG; do
  echo "🔄 Processing $SERVICE_TAG ($INSTANCE_ID)"

  # Fetch both IPs
  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

  PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)

  # Decide which IP to use
  if [[ "$SERVICE_TAG" == "frontend" ]]; then
    SELECTED_IP="$PUBLIC_IP"
  else
    SELECTED_IP="$PRIVATE_IP"
  fi

  # Skip if IP is empty or None
  if [[ -z "$SELECTED_IP" || "$SELECTED_IP" == "None" ]]; then
    echo "⚠️  Skipping $SERVICE_TAG due to missing IP"
    continue
  fi

  # Create/Update Route53 record for selected IP
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"${SERVICE_TAG}.sharkdev.shop\",
          \"Type\": \"A\",
          \"TTL\": 5,
          \"ResourceRecords\": [{\"Value\": \"${SELECTED_IP}\"}]
        }
      }]
    }"

  echo "✅ DNS record set for $SERVICE_TAG → $SELECTED_IP"

done <<< "$instances"

echo "✅ All 11 DNS records updated successfully."
