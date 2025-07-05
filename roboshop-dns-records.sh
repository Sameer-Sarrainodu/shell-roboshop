#!/bin/bash

ZONE_ID="Z0022572U6LHZ3ASAGBB"

# Get instances with Name tag containing *latest
instances=$(aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" "Name=tag:Name,Values=*latest" \
  --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='service']|[0].Value]" \
  --output text)

# Loop through instance ID and service tag
while read -r INSTANCE_ID SERVICE_TAG; do
  echo "Processing $INSTANCE_ID ($SERVICE_TAG)"

  # Fetch public and private IP
  PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

  PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)

  # Skip if public IP is missing
  if [[ -z "$PUBLIC_IP" || "$PUBLIC_IP" == "None" ]]; then
    echo "Skipping $SERVICE_TAG due to missing public IP"
    continue
  fi

  # Public DNS record: service.sharkdev.shop
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"${SERVICE_TAG}.sharkdev.shop\",
          \"Type\": \"A\",
          \"TTL\": 5,
          \"ResourceRecords\": [{\"Value\": \"${PUBLIC_IP}\"}]
        }
      }]
    }"

  # Private DNS record: private.service.sharkdev.shop
  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "{
      \"Changes\": [{
        \"Action\": \"UPSERT\",
        \"ResourceRecordSet\": {
          \"Name\": \"private.${SERVICE_TAG}.sharkdev.shop\",
          \"Type\": \"A\",
          \"TTL\": 5,
          \"ResourceRecords\": [{\"Value\": \"${PRIVATE_IP}\"}]
        }
      }]
    }"

  echo "✅ DNS updated for $SERVICE_TAG"

done <<< "$instances"

echo "✅ All DNS updates completed."
