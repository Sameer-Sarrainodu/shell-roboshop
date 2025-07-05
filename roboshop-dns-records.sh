#!/bin/bash

ZONE_ID="Z0022572U6LHZ3ASAGBB"

# Fetch running instances with 'service' tag (matching instance creation script)
instances=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:service,Values=*" \
  --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='service']|[0].Value]" \
  --output text)

# Check if instances are found
if [[ -z "$instances" ]]; then
  echo "⚠️ No running instances found with service tag"
  exit 1
fi

# Loop through each instance line
while read -r INSTANCE_ID SERVICE_TAG; do
  # Validate INSTANCE_ID and SERVICE_TAG
  if [[ -z "$INSTANCE_ID" || -z "$SERVICE_TAG" ]]; then
    echo "⚠️ Skipping invalid instance: INSTANCE_ID=$INSTANCE_ID, SERVICE_TAG=$SERVICE_TAG"
    continue
  fi

  echo "🔄 Processing $SERVICE_TAG ($INSTANCE_ID)"

  # Fetch both IPs
  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text 2>/dev/null)

  PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text 2>/dev/null)

  # Decide which IP to use
  if [[ "$SERVICE_TAG" == "frontend" ]]; then
    SELECTED_IP="$PUBLIC_IP"
  else
    SELECTED_IP="$PRIVATE_IP"
  fi

  # Skip if IP is empty or None
  if [[ -z "$SELECTED_IP" || "$SELECTED_IP" == "None" ]]; then
    echo "⚠️ Skipping $SERVICE_TAG due to missing IP"
    continue
  fi

  # Set domain name based on service tag
  if [[ "$SERVICE_TAG" == "frontend" ]]; then
    DOMAIN_NAME="sharkdev.shop"
  else
    DOMAIN_NAME="${SERVICE_TAG}.sharkdev.shop"
  fi

  # Create/Update Route53 record for selected IP
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"${DOMAIN_NAME}\",
          \"Type\": \"A\",
          \"TTL\": 5,
          \"ResourceRecords\": [{\"Value\": \"${SELECTED_IP}\"}]
        }
      }]
    }" 2>/dev/null || { echo "❌ Failed to update DNS for $DOMAIN_NAME"; continue; }

  echo "✅ DNS record set for $DOMAIN_NAME → $SELECTED_IP"

done <<< "$instances"

echo "✅ All DNS records updated successfully."