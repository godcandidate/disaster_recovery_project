#!/bin/bash

# Use the values directly passed from Terraform
DB_HOST='${DB_HOST_PARAM}'
DB_PORT='${DB_PORT_PARAM}'
DB_NAME='${DB_NAME_PARAM}'
DB_USER='${DB_USER_PARAM}'
DB_PASSWORD='${DB_PASSWORD_PARAM}'
S3_BUCKET_ID='${S3_BUCKET_ID_PARAM}'
S3_BUCKET_REGION='${S3_BUCKET_REGION_PARAM}'


# Update docker-compose.yml with the values
sed -i -E \
  -e "s|^( *DB_HOST:).*|\1 ${DB_HOST_PARAM}|" \
  -e "s|^( *AWS_REGION:).*|\1 ${S3_BUCKET_REGION_PARAM}|" \
  -e "s|^( *AWS_BUCKET_NAME:).*|\1 ${S3_BUCKET_ID_PARAM}|" \
  /app/docker-compose.yml

# Start the application
cd /app
docker-compose up -d
STARTUP

chmod +x /usr/local/bin/start-application.sh

# Set up cron job to start the application on reboot



# Start the application
cd /app
docker-compose up -d