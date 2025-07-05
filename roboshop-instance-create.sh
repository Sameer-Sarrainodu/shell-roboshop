AMI_ID="ami-09c813fb71547fc4f"
INSTANCE_TYPE="t2.micro"
SECURITY_GROUP_ID="sg-0e431449e6b8a4604"
ZONE_ID="Z0022572U6LHZ3ASAGBB"

instances=("frontend" "mongodb" "catalogue" "reids" "user" "cart" "shipping" "payment" "dispatch")

if aws --version &> /dev/null; then
    echo "aws cli is installed"
else
    dnf install awscli -y
fi

if git --version &> /dev/null; then
    echo "git is installed"
else
    dnf install git -y
fi

git clone https://github.com/Sameer-Sarrainodu/shell-roboshop.git

for instance in "${instances[@]}"; do
  echo "Creating $instance instance"
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --security-group-ids "$SECURITY_GROUP_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance-latest},{Key=service,Value=$instance}]" \
    --query "Instances[0].InstanceId" \
    --output text)

    echo "created instance with id $INSTANCE_ID"
done



