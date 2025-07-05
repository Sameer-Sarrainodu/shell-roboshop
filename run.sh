#!/bin/bash

PASSWORD="DevOps321"
USER="ec2-user"
DOMAIN="sharkdev.shop"

services=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")

for service in "${services[@]}"; do
  echo "Connecting to $service"

  sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "$USER@$service.$DOMAIN" 'bash -s' <<EOF
cd /home/ec2-user
if [ ! -d "shell-roboshop" ]; then
  git clone https://github.com/Sameer-Sarrainodu/shell-roboshop.git
fi
cd shell-roboshop
git reset --hard HEAD      # Discards local changes
git pull                   # Pulls latest from remote
chmod +x $service.sh
sudo bash $service.sh
EOF

done