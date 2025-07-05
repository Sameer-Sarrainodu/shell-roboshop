#!/bin/bash

# Script to delete Route53 DNS records for specified services

ZONE_ID="Z0022572U6LHZ3ASAGBB"
instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payment" "dispatch")

# Check for AWS CLI
if aws --version &> /dev/null; then
    echo "✅ AWS CLI is installed"
else
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Loop through each service to delete DNS records
for instance in "${instances[@]}"; do
    # Set domain name based on service
    if [[ "$instance" == "frontend" ]]; then
        DOMAIN_NAME="sharkdev.shop"
    else
        DOMAIN_NAME="${instance}.sharkdev.shop"
    fi

    echo "🔍 Checking for DNS record for $DOMAIN_NAME..."

    # Check if the DNS record exists
    RECORD_EXISTS=$(aws route53 list-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --query "ResourceRecordSets[?Name=='${DOMAIN_NAME}.']|[?Type=='A']" \
        --output text 2>/dev/null)

    if [[ -z "$RECORD_EXISTS" ]]; then
        echo "⚠️ No A record found for $DOMAIN_NAME"
        continue
    fi

    # Delete the DNS record
    echo "🗑️ Deleting DNS record for $DOMAIN_NAME..."
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "{
            \"Changes\": [{
                \"Action\": \"DELETE\",
                \"ResourceRecordSet\": {
                    \"Name\": \"${DOMAIN_NAME}\",
                    \"Type\": \"A\",
                    \"TTL\": 5,
                    \"ResourceRecords\": [{\"Value\": \"0.0.0.0\"}]
                }
            }]
        }" 2>/dev/null || { echo "❌ Failed to delete DNS record for $DOMAIN_NAME"; continue; }

    echo "✅ Deleted DNS record for $DOMAIN_NAME"
done

echo "✅ All specified DNS records deleted successfully."