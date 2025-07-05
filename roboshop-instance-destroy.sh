#!/bin/bash

# Script to terminate EC2 instances with specific service tags

# Configuration
instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payment" "dispatch")

# Check for AWS CLI
if aws --version &> /dev/null; then
    echo "✅ AWS CLI is installed"
else
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Loop through each service to find and terminate instances
for instance in "${instances[@]}"; do
    echo "🔍 Searching for $instance instance..."

    # Fetch instance IDs with the specific service tag
    INSTANCE_IDS=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" "Name=tag:service,Values=$instance" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text 2>/dev/null)

    # Check if any instances were found
    if [[ -z "$INSTANCE_IDS" ]]; then
        echo "⚠️ No running instances found for $instance"
        continue
    fi

    # Terminate each instance
    for INSTANCE_ID in $INSTANCE_IDS; do
        echo "🗑️ Terminating $instance instance ($INSTANCE_ID)..."
        aws ec2 terminate-instances \
            --instance-ids "$INSTANCE_ID" \
            --output text 2>/dev/null || { echo "❌ Failed to terminate $instance ($INSTANCE_ID)"; continue; }

        # Wait for instance to be terminated
        echo "⏳ Waiting for $instance ($INSTANCE_ID) to terminate..."
        aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" 2>/dev/null || { echo "❌ Failed to wait for termination of $instance ($INSTANCE_ID)"; continue; }
        echo "✅ Terminated $instance ($INSTANCE_ID)"
    done
done

echo "✅ All specified instances terminated successfully."