# #!/bin/bash

# AMI_ID="ami-09c813fb71547fc4f"
# INSTANCE_TYPE="t2.micro"
# SECURITY_GROUP_ID="sg-0e431449e6b8a4604"
# ZONE_ID="Z0022572U6LHZ3ASAGBB"

# instances=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payment" "dispatch")

# # Check for AWS CLI
# if aws --version &> /dev/null; then
#     echo "✅ AWS CLI is installed"
# else
#     echo "📦 Installing AWS CLI..."
#     dnf install awscli -y
# fi

# # Check for Git
# if git --version &> /dev/null; then
#     echo "✅ Git is installed"
# else
#     echo "📦 Installing Git..."
#     dnf install git -y
# fi

# # Clone the repo (skip if already exists)
# if [ ! -d "shell-roboshop" ]; then
#   git clone https://github.com/Sameer-Sarrainodu/shell-roboshop.git
# fi

# # Launch EC2 Instances
# for instance in "${instances[@]}"; do
#   echo "🚀 Creating $instance instance..."

#   INSTANCE_ID=$(aws ec2 run-instances \
#     --image-id "$AMI_ID" \
#     --instance-type "$INSTANCE_TYPE" \
#     --security-group-ids "$SECURITY_GROUP_ID" \
#     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance},{Key=service,Value=$instance}]" \
#     --query "Instances[0].InstanceId" \
#     --output text)

#   echo "✅ Created $instance with Instance ID: $INSTANCE_ID"
# done

#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
INSTANCE_TYPE="t2.micro"
SECURITY_GROUP_ID="sg-0e431449e6b8a4604"
ZONE_ID="Z0022572U6LHZ3ASAGBB"

# Check for arguments
if [ "$#" -eq 0 ]; then
  echo "❌ No instance names provided. Usage: $0 frontend mongodb redis ..."
  exit 1
fi

# Check for AWS CLI
if ! command -v aws &>/dev/null; then
  echo "📦 Installing AWS CLI..."
  dnf install awscli -y
else
  echo "✅ AWS CLI is installed"
fi

# Check for Git
if ! command -v git &>/dev/null; then
  echo "📦 Installing Git..."
  dnf install git -y
else
  echo "✅ Git is installed"
fi

# Clone the repo if not already present
if [ ! -d "shell-roboshop" ]; then
  git clone https://github.com/Sameer-Sarrainodu/shell-roboshop.git
fi

# Use arguments instead of hardcoded list
for instance in "$@"; do
  echo "🚀 Creating $instance instance..."

  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance},{Key=service,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)

  echo "✅ Created $instance with Instance ID: $INSTANCE_ID"
done




