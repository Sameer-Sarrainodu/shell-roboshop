#!/bin/bash

PASSWORD="DevOps321"
USER="ec2-user"
DOMAIN="sharkdev.shop"

# List of valid services
services=("frontend" "mongodb" "catalogue" "redis" "user" "cart" "mysql" "shipping" "rabbitmq" "payment" "dispatch")

# Define colors
green="\e[32m"
red="\e[31m"
yellow="\e[33m"
nc="\e[0m"

# Validate service
valid_service() {
  for s in "${services[@]}"; do
    if [[ "$s" == "$1" ]]; then
      return 0
    fi
  done
  return 1
}

# Check if at least one service is passed
if [ $# -eq 0 ]; then
  echo -e "${red}❌ No service name passed. Usage: ./run.sh <service1> <service2> ...${nc}"
  exit 1
fi

# Loop through each argument passed
for service in "$@"; do
  if valid_service "$service"; then
    echo -e "${yellow}🔁 Connecting to $service...${nc}"

    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$service.$DOMAIN" 'bash -s' <<EOF
cd /home/ec2-user
if [ ! -d "shell-roboshop" ]; then
  git clone https://github.com/Sameer-Sarrainodu/shell-roboshop.git
fi
cd shell-roboshop
git reset --hard HEAD
git pull
chmod +x $service.sh
sudo bash $service.sh
EOF

    echo -e "${green}✅ $service deployed successfully.${nc}"
  else
    echo -e "${red}❌ Invalid service name: $service${nc}"
  fi
done
