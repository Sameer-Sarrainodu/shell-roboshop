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

# Counter for successful deletions
SUCCESS_COUNT=0

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
    RECORD=$(aws route53 list-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --query "ResourceRecordSets[?Name=='${DOMAIN_NAME}.']|[?Type=='A']" \
        --output json 2>/dev/null)

    if [[ -z "$RECORD" || "$RECORD" == "[]" ]]; then
        echo "⚠️ No A record found for $DOMAIN_NAME"
        continue
    fi

    # Extract the current TTL and ResourceRecords for the DELETE action
    TTL=$(echo "$RECORD" | jq -r '.[0].TTL')
    RESOURCE_RECORDS=$(echo "$RECORD" | jq -r '.[0].ResourceRecords')

    # Delete the DNS record
    echo "🗑️ Deleting DNS record for $DOMAIN_NAME..."
    DELETE_RESULT=$(aws route53 change-resource-record-sets \
        --hosted-zone-id "$ZONE_ID" \
        --change-batch "{
            \"Changes\": [{
                \"Action\": \"DELETE\",
                \"ResourceRecordSet\": {
                    \"Name\": \"${DOMAIN_NAME}\",
                    \"Type\": \"A\",
                    \"TTL\": $TTL,
                    \"ResourceRecords\": $RESOURCE_RECORDS
                }
            }]
        }" 2>&1)

    if [[ $? -eq 0 ]]; then
        echo "✅ Deleted DNS record for $DOMAIN_NAME"
        ((SUCCESS_COUNT++))
    else
        echo "❌ Failed to delete DNS record for $DOMAIN_NAME: $DELETE_RESULT"
    fi
done

# Final summary
echo "✅ Completed: $SUCCESS_COUNT DNS records deleted successfully."