#!/bin/bash
set -e

# Update system
yum update -y

# Install Python 3.11
yum install -y python3.11 python3.11-pip

# Install PostgreSQL client
amazon-linux-extras install postgresql14 -y

# Install Git
yum install -y git

# Install Docker (optional)
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install nginx (optional - for reverse proxy)
amazon-linux-extras install nginx1 -y
systemctl start nginx
systemctl enable nginx

# Create application directory
mkdir -p /opt/medilink
chown ec2-user:ec2-user /opt/medilink

# Set up environment file
cat > /opt/medilink/.env.example << 'EOF'
DATABASE_URL=postgresql://username:password@rds-endpoint:5432/medilink
SECRET_KEY=your-secret-key-here
ENVIRONMENT=production
EOF

chown ec2-user:ec2-user /opt/medilink/.env.example

# Install CloudWatch agent (optional but recommended)
wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U ./amazon-cloudwatch-agent.rpm

echo "Bootstrap completed successfully" > /var/log/user-data.log