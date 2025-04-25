#!/bin/bash

# Minimal logging
echo "DR Region User Data Script Started" > /var/log/dr-userdata.log

# Update docker-compose.yml with the correct values
if [ -f /app/docker-compose.yml ]; then
  sed -i -E \
    -e "s|^( *DB_HOST:).*|\1 ${DB_HOST_PARAM}|" \
    -e "s|^( *AWS_REGION:).*|\1 ${S3_BUCKET_REGION_PARAM}|" \
    -e "s|^( *AWS_BUCKET_NAME:).*|\1 ${S3_BUCKET_ID_PARAM}|" \
    /app/docker-compose.yml
  echo "docker-compose.yml updated with DB_HOST=${DB_HOST_PARAM}, AWS_REGION=${S3_BUCKET_REGION_PARAM}, AWS_BUCKET_NAME=${S3_BUCKET_ID_PARAM}" >> /var/log/dr-userdata.log
fi

# Start the application
cd /app
docker-compose up -d

echo "DR Region User Data Script Completed" >> /var/log/dr-userdata.log
