#!/bin/bash

# Script to terminate all EC2 instances with specific service tags in a single batch

# Configuration
instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payment" "dispatch")

# Check for AWS CLI
if aws --version &> /dev/null; then
    echo "✅ AWS CLI is installed"
else
    echo "❌ AWS CLI is not installed. Please install it first."
    exit 1
fi

# Collect all instance IDs for the specified service tags
echo "🔍 Searching for instances with service tags..."
ALL_INSTANCE_IDS=()

for instance in "${instances[@]}"; do
    # Fetch instance IDs with the specific service tag
    INSTANCE_IDS=$(aws ec2 describe-instances \
        --filters "Name=instance-state-name,Values=running" "Name=tag:service,Values=$instance" \
        --query "Reservations[*].Instances[*].InstanceId" \
        --output text 2>&1)

    # Check if the command failed
    if [[ $? -ne 0 ]]; then
        echo "❌ Error fetching instances for $instance: $INSTANCE_IDS"
        continue
    fi

    # Add found instance IDs to the array
    if [[ -n "$INSTANCE_IDS" ]]; then
        for ID in $INSTANCE_IDS; do
            ALL_INSTANCE_IDS+=("$ID|$instance")
        done
        echo "✅ Found instances for $instance: $INSTANCE_IDS"
    else
        echo "⚠️ No running instances found for $instance"
    fi
done

# Check if any instances were found
if [[ ${#ALL_INSTANCE_IDS[@]} -eq 0 ]]; then
    echo "⚠️ No running instances found for any specified service tags"
    exit 1
fi

# Extract just the instance IDs for termination
TERMINATE_IDS=()
for ENTRY in "${ALL_INSTANCE_IDS[@]}"; do
    TERMINATE_IDS+=("${ENTRY%%|*}")
done

# Terminate all instances in a single batch
echo "🗑️ Terminating ${#TERMINATE_IDS[@]} instances: ${TERMINATE_IDS[*]}..."
TERMINATE_RESULT=$(aws ec2 terminate-instances \
    --instance-ids "${TERMINATE_IDS[@]}" \
    --output text 2>&1)

if [[ $? -eq 0 ]]; then
    # Wait for all instances to be terminated
    echo "⏳ Waiting for all instances to terminate..."
    aws ec2 wait instance-terminated --instance-ids "${TERMINATE_IDS[@]}" 2>&1 || {
        echo "❌ Failed to wait for termination of some instances"
    }

    # Verify termination status
    SUCCESS_COUNT=0
    for ENTRY in "${ALL_INSTANCE_IDS[@]}"; do
        INSTANCE_ID="${ENTRY%%|*}"
        SERVICE="${ENTRY#*|}"
        STATUS=$(aws ec2 describe-instances \
            --instance-ids "$INSTANCE_ID" \
            --query "Reservations[0].Instances[0].State.Name" \
            --output text 2>&1)
        if [[ "$STATUS" == "terminated" ]]; then
            echo "✅ Terminated $SERVICE ($INSTANCE_ID)"
            ((SUCCESS_COUNT++))
        else
            echo "❌ $SERVICE ($INSTANCE_ID) is in state: $STATUS"
        fi
    done
else
    echo "❌ Failed to terminate instances: $TERMINATE_RESULT"
    exit 1
fi

echo "✅ Completed: $SUCCESS_COUNT instances terminated successfully."