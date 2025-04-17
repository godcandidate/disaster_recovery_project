#!/bin/bash
echo "Setting up EC2 instance in DR region"

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

# Create a script to set database credentials directly from Terraform variables
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
      - NEXT_PUBLIC_API_BASE_URL=http://localhost:5000/todos
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
      DB_HOST: \${DB_HOST}
      DB_NAME: \${DB_NAME}
      DB_USER: \${DB_USER}
      DB_PASSWORD: \${DB_PASSWORD}
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

# Create failover script for database promotion
cat > /usr/local/bin/promote-dr-database.sh << SCRIPT
#!/bin/bash
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Since we're not using SSM Parameter Store, we'll use the DB instance ID directly
DB_INSTANCE_ID="dr-db-dr-replica"

echo "Promoting read replica to standalone database instance..."
aws rds promote-read-replica --db-instance-identifier $DB_INSTANCE_ID --region $REGION

echo "Waiting for promotion to complete..."
aws rds wait db-instance-available --db-instance-identifier $DB_INSTANCE_ID --region $REGION

echo "Database promotion complete. The DR database is now a standalone instance."

# Get the new endpoint after promotion
NEW_DB_HOST=$(aws rds describe-db-instances --db-instance-identifier $DB_INSTANCE_ID --region $REGION --query "DBInstances[0].Endpoint.Address" --output text)

# Update the DB_HOST environment variable
echo "export DB_HOST=\"$NEW_DB_HOST\"" >> /usr/local/bin/get-db-credentials.sh

echo "Updated database host to: $NEW_DB_HOST"
SCRIPT

chmod +x /usr/local/bin/promote-dr-database.sh

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

# Create failover procedure script
cat > /usr/local/bin/failover-procedure.sh << FAILOVER
#!/bin/bash
echo "Starting DR failover procedure..."

# Step 1: Promote the read replica to a standalone database
/usr/local/bin/promote-dr-database.sh

# Step 2: Wait a moment for the promotion to complete
sleep 30

# Step 3: Get the updated database credentials
source /usr/local/bin/get-db-credentials.sh

# Step 4: Start the application
/usr/local/bin/start-application.sh

echo "Failover procedure completed successfully. The application is now running in DR mode."
FAILOVER

chmod +x /usr/local/bin/failover-procedure.sh

# Note: In DR mode, the application is not started automatically
# It will only be started when the failover procedure is executed

echo "DR environment setup complete"
