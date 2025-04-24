#!/bin/bash

# Install Docker and Docker Compose
yum update -y
yum install -y docker awscli amazon-ssm-agent
systemctl start docker amazon-ssm-agent
systemctl enable docker amazon-ssm-agent
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Create script to fetch database credentials from SSM Parameter Store
cat > /usr/local/bin/get-db-credentials.sh << 'EOF'
#!/bin/bash

# Set region and parameter names from environment variables
REGION='${REGION}'
DB_HOST_PARAM='${DB_HOST_PARAM}'
DB_PORT_PARAM='${DB_PORT_PARAM}'
DB_NAME_PARAM='${DB_NAME_PARAM}'
DB_USER_PARAM='${DB_USER_PARAM}'
DB_PASSWORD_PARAM='${DB_PASSWORD_PARAM}'
S3_BUCKET_ID_PARAM='${S3_BUCKET_ID_PARAM}'
S3_BUCKET_REGION_PARAM='${S3_BUCKET_REGION_PARAM}'
AWS_ACCESS_KEY='${AWS_ACCESS_KEY}'
AWS_SECRET_KEY='${AWS_SECRET_KEY}'
# Function to get parameter value from SSM
get_parameter() {
  local param_name=$1
  aws ssm get-parameter --name "$param_name" --with-decryption --region "$REGION" --query "Parameter.Value" --output text 2>/dev/null
}

# Get parameters
DB_HOST=$(get_parameter "$DB_HOST_PARAM")
DB_PORT=$(get_parameter "$DB_PORT_PARAM")
DB_NAME=$(get_parameter "$DB_NAME_PARAM")
DB_USER=$(get_parameter "$DB_USER_PARAM")
DB_PASSWORD=$(get_parameter "$DB_PASSWORD_PARAM")
S3_BUCKET_ID=$(get_parameter "$S3_BUCKET_ID_PARAM")
S3_BUCKET_REGION=$(get_parameter "$S3_BUCKET_REGION_PARAM")

# Export the variables
export DB_HOST DB_PORT DB_NAME DB_USER DB_PASSWORD S3_BUCKET_ID S3_BUCKET_REGION
EOF

chmod +x /usr/local/bin/get-db-credentials.sh

# Get the EC2 instance's public IP address
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Create docker-compose.yml file
mkdir -p /app
cat > /app/docker-compose.yml << 'DOCKER_COMPOSE'
version: '3.8'

services:
  # Image Gallery App
  app:
    image: godcandidate/image-gallery-app:latest
    restart: always
    ports:
      - "80:3001"
    environment:
      # Database
      DB_HOST: DB_HOST_VALUE
      DB_NAME: DB_NAME_VALUE
      DB_USER: DB_USER_VALUE
      DB_PASSWORD: DB_PASSWORD_VALUE
      PORT: 3001
      # AWS S3
      AWS_REGION: AWS_REGION_VALUE
      AWS_ACCESS_KEY_ID: AWS_ACCESS_KEY_ID_VALUE
      AWS_SECRET_ACCESS_KEY: AWS_SECRET_ACCESS_KEY_VALUE
      AWS_BUCKET_NAME: AWS_BUCKET_NAME_VALUE

# Networks
networks:
  app-network:
    driver: bridge
DOCKER_COMPOSE



# Create startup script for dynamic parameter retrieval on boot
cat > /usr/local/bin/start-application.sh << 'STARTUP'
#!/bin/bash
# Get fresh values from SSM on each boot
source /usr/local/bin/get-db-credentials.sh

# Get AWS credentials (from variables or instance metadata)
if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ]; then
  TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  ROLE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/)
  CREDS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE)
  AWS_ACCESS_KEY=$(echo $CREDS | grep -o '"AccessKeyId" : "[^"]*"' | cut -d '"' -f 4)
  AWS_SECRET_KEY=$(echo $CREDS | grep -o '"SecretAccessKey" : "[^"]*"' | cut -d '"' -f 4)
fi

# Update docker-compose with actual values
sed -i "s/DB_HOST_VALUE/$DB_HOST/g" /app/docker-compose.yml
sed -i "s/DB_NAME_VALUE/$DB_NAME/g" /app/docker-compose.yml
sed -i "s/DB_USER_VALUE/$DB_USER/g" /app/docker-compose.yml
sed -i "s/DB_PASSWORD_VALUE/$DB_PASSWORD/g" /app/docker-compose.yml
sed -i "s/AWS_REGION_VALUE/$S3_BUCKET_REGION/g" /app/docker-compose.yml
sed -i "s/AWS_ACCESS_KEY_ID_VALUE/$AWS_ACCESS_KEY/g" /app/docker-compose.yml
sed -i "s/AWS_SECRET_ACCESS_KEY_VALUE/$AWS_SECRET_KEY/g" /app/docker-compose.yml
sed -i "s/AWS_BUCKET_NAME_VALUE/$S3_BUCKET_ID/g" /app/docker-compose.yml

# Start the application
cd /app
docker-compose up -d
STARTUP

chmod +x /usr/local/bin/start-application.sh

# Set up cron job to start the application on reboot
echo "@reboot root /usr/local/bin/start-application.sh" > /etc/cron.d/start-application

# Start the application
/usr/local/bin/start-application.sh