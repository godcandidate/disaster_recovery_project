#!/bin/bash
echo "Setting up EC2 instance in Primary region"

# Install Docker and Docker Compose
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install AWS CLI and SSM agent
yum install -y awscli amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

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

# Add debugging
echo "Attempting to retrieve parameters from region: $REGION"
echo "Parameter names:"
echo "- Host: $DB_HOST_PARAM"
echo "- Port: $DB_PORT_PARAM"
echo "- Name: $DB_NAME_PARAM"
echo "- User: $DB_USER_PARAM"
echo "- Password: $DB_PASSWORD_PARAM (value will be hidden)"

# Fetch database credentials from SSM Parameter Store with error handling
get_parameter() {
  local param_name=$1
  local param_value
  
  echo "Retrieving parameter: $param_name"
  param_value=$(aws ssm get-parameter --name "$param_name" --with-decryption --region "$REGION" --query "Parameter.Value" --output text 2>/tmp/ssm_error.log)
  
  if [ $? -ne 0 ]; then
    echo "Error retrieving parameter $param_name:"
    cat /tmp/ssm_error.log
    return 1
  fi
  
  echo "$param_value"
}

# Get each parameter with error handling - capture only the output value
get_clean_parameter() {
  local param_name=$1
  local param_value
  
  # Redirect all output to /dev/null except the actual parameter value
  param_value=$(aws ssm get-parameter --name "$param_name" --with-decryption --region "$REGION" --query "Parameter.Value" --output text 2>/dev/null)
  
  if [ $? -ne 0 ]; then
    echo "Error retrieving parameter $param_name" >&2
    return 1
  fi
  
  echo "$param_value"
}

# Get each parameter with clean output
DB_HOST=$(get_clean_parameter "$DB_HOST_PARAM")
DB_PORT=$(get_clean_parameter "$DB_PORT_PARAM")
DB_NAME=$(get_clean_parameter "$DB_NAME_PARAM")
DB_USER=$(get_clean_parameter "$DB_USER_PARAM")
DB_PASSWORD=$(get_clean_parameter "$DB_PASSWORD_PARAM")

# Export the variables
export DB_HOST
export DB_PORT
export DB_NAME
export DB_USER
export DB_PASSWORD

# Verify parameters were retrieved
echo "Parameter retrieval status:"
if [ -n "$DB_HOST" ]; then echo "- DB_HOST: Retrieved successfully"; else echo "- DB_HOST: Failed"; fi
if [ -n "$DB_PORT" ]; then echo "- DB_PORT: Retrieved successfully"; else echo "- DB_PORT: Failed"; fi
if [ -n "$DB_NAME" ]; then echo "- DB_NAME: Retrieved successfully"; else echo "- DB_NAME: Failed"; fi
if [ -n "$DB_USER" ]; then echo "- DB_USER: Retrieved successfully"; else echo "- DB_USER: Failed"; fi
if [ -n "$DB_PASSWORD" ]; then echo "- DB_PASSWORD: Retrieved successfully"; else echo "- DB_PASSWORD: Failed"; fi

echo "Database credentials fetched from SSM Parameter Store"
EOF

chmod +x /usr/local/bin/get-db-credentials.sh

# Get the EC2 instance's public IP address at runtime
EC2_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Create docker-compose.yml file
mkdir -p /app
cat > /app/docker-compose.yml << 'DOCKER_COMPOSE'
version: '3.8'

services:
  # Frontend Service
  frontend:
    image: godcandidate/lamp-stack-frontend:latest
    container_name: frontend
    environment:
      - NEXT_PUBLIC_API_BASE_URL=http://PUBLIC_IP:5000/todos
    ports:
      - "80:3000" 
    depends_on:
      - backend
    networks:
      - app-network
    restart: always

  # Backend Service
  backend:
    image: godcandidate/lamp-stack-backend:latest
    container_name: backend
    env_file:
      - /app/.env
    ports:
      - "5000:80"
    networks:
      - app-network
    restart: always

# Networks
networks:
  app-network:
    driver: bridge
DOCKER_COMPOSE

# Replace the placeholder with the actual IP
sed -i "s/PUBLIC_IP/$EC2_IP/g" /app/docker-compose.yml

# Create startup script
cat > /usr/local/bin/start-application.sh << 'STARTUP'
#!/bin/bash
# Source the database credentials
source /usr/local/bin/get-db-credentials.sh

# Create .env file for the backend service with clean values
echo "DB_HOST=$DB_HOST" > /app/.env
echo "DB_NAME=$DB_NAME" >> /app/.env
echo "DB_USER=$DB_USER" >> /app/.env
echo "DB_PASSWORD=$DB_PASSWORD" >> /app/.env

# Start the application with docker-compose
cd /app
docker-compose up -d

echo "Application started successfully"
STARTUP

chmod +x /usr/local/bin/start-application.sh

# Set up cron job to start the application on reboot
echo "@reboot root /usr/local/bin/start-application.sh" > /etc/cron.d/start-application

# Start the application
/usr/local/bin/start-application.sh

echo "Primary environment setup complete"
