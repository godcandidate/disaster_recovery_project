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
sed -i "s/DB_HOST/$DB_HOST/g" /app/docker-compose.yml
sed -i "s/AWS_REGION/$S3_BUCKET_REGION/g" /app/docker-compose.yml
sed -i "s/AWS_BUCKET_NAME/$S3_BUCKET_ID/g" /app/docker-compose.yml



# Start the application
cd /app
docker-compose up -d