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

# Install AWS CLI
yum install -y awscli

# We can use the variables passed directly from Terraform
# Export variables for docker-compose
cat > /usr/local/bin/get-db-credentials.sh << SCRIPT
#!/bin/bash

# Export database credentials directly from Terraform variables
export DB_HOST="${DB_HOST}"
export DB_NAME="${DB_NAME}"
export DB_USER="${DB_USER}"
export DB_PASSWORD="${DB_PASSWORD}"

echo "Database credentials set for docker-compose"
SCRIPT

chmod +x /usr/local/bin/get-db-credentials.sh
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
      - NEXT_PUBLIC_API_BASE_URL=http://${EC2_IP}:5000/todos
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
    environment:
      DB_HOST: ${DB_HOST}
      DB_NAME: ${DB_NAME}
      DB_USER: ${DB_USER}
      DB_PASSWORD: ${DB_PASSWORD}
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

# Create startup script
cat > /usr/local/bin/start-application.sh << 'STARTUP'
#!/bin/bash
# Source the database credentials
source /usr/local/bin/get-db-credentials.sh

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
