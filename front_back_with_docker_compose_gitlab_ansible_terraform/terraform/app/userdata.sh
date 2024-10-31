#!/bin/bash

# Install docker, git, unzip, nano
yum update -y
yum install docker git unzip nano -y
systemctl enable docker.service
systemctl start docker.service

# Install docker-compose plugin
mkdir -p /usr/local/lib/docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Add docker-compose user
useradd --comment 'Docker Compose' --create-home compose --shell /bin/bash

# Add user "compose" to docker group
usermod -aG docker compose

# Create app folder and prepare .ssh/authtorized_key
mkdir /home/compose/app
mkdir /home/compose/.ssh && chmod 700 /home/compose/.ssh 
touch /home/compose/.ssh/authorized_keys && chmod 600 /home/compose/.ssh/authorized_keys

mkdir -p /home/compose/db_backups/daily
mkdir -p /home/compose/db_backups/monthly

chown -R compose:compose /home/compose/

reboot
