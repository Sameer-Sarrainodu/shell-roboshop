#!/bin/bash
for instance in "${instances[@]}"; do
  echo "🧨 Processing instance: $instance"

  INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=${instance}-latest" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)

  if [[ "$INSTANCE_ID" == "None" || "$INSTANCE_ID" == "null" || -z "$INSTANCE_ID" ]]; then
    echo "⚠️  No running instance found with tag ${instance}-latest"
    continue
  fi

  echo "✏️ Renaming $instance to ${instance}-old"
  aws ec2 create-tags --resources "$INSTANCE_ID" --tags "Key=Name,Value=${instance}-old"

  echo "💣 Terminating instance $INSTANCE_ID"
  aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
done

echo "✅ All instances terminated and DNS records cleaned up."