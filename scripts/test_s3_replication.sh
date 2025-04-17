#!/bin/bash

# Script to test S3 cross-region replication
# This script uploads test files to the primary bucket and verifies they are replicated to the DR bucket

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get the bucket names from Terraform outputs
echo -e "${YELLOW}Getting S3 bucket information from Terraform...${NC}"
cd /home/edward/Desktop/Labs_Repo/devops_labs/disaster_recovery_project/environments/primary

PRIMARY_BUCKET=$(terraform output -raw s3_primary_bucket_id)
DR_BUCKET=$(terraform output -raw s3_dr_bucket_id)
PRIMARY_REGION=$(terraform output -raw region)
DR_REGION=$(terraform output -raw dr_region)

if [ -z "$PRIMARY_BUCKET" ] || [ -z "$DR_BUCKET" ]; then
  echo -e "${RED}Failed to get bucket names from Terraform outputs.${NC}"
  echo "Make sure you have applied the Terraform configuration and the outputs are available."
  exit 1
fi

echo -e "${GREEN}Primary bucket: ${PRIMARY_BUCKET} (${PRIMARY_REGION})${NC}"
echo -e "${GREEN}DR bucket: ${DR_BUCKET} (${DR_REGION})${NC}"

# Create test files
echo -e "${YELLOW}Creating test files...${NC}"
mkdir -p /tmp/s3-test-files
cd /tmp/s3-test-files

# Create 3 test files with timestamps
for i in {1..3}; do
  echo "Test file $i - Created at $(date)" > "test-file-$i.txt"
  echo -e "${GREEN}Created test-file-$i.txt${NC}"
done

# Create a small image file (1KB)
dd if=/dev/urandom of=test-image.jpg bs=1024 count=1
echo -e "${GREEN}Created test-image.jpg${NC}"

# Upload files to the primary bucket's production/media folder
echo -e "${YELLOW}Uploading files to primary bucket...${NC}"
for file in *; do
  aws s3 cp "$file" "s3://${PRIMARY_BUCKET}/production/media/$file" --region $PRIMARY_REGION
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Uploaded $file to primary bucket${NC}"
  else
    echo -e "${RED}Failed to upload $file to primary bucket${NC}"
  fi
done

# Wait for replication to complete (S3 replication typically takes a few minutes)
echo -e "${YELLOW}Waiting for replication to complete (60 seconds)...${NC}"
sleep 60

# Check if files were replicated to the DR bucket
echo -e "${YELLOW}Checking replication to DR bucket...${NC}"
for file in *; do
  aws s3api head-object --bucket $DR_BUCKET --key "production/media/$file" --region $DR_REGION &>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ File $file was successfully replicated to DR bucket${NC}"
  else
    echo -e "${RED}✗ File $file was NOT replicated to DR bucket${NC}"
  fi
done

# Clean up
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
cd /
rm -rf /tmp/s3-test-files
echo -e "${GREEN}Temporary files removed${NC}"

echo -e "${GREEN}S3 replication test completed!${NC}"
echo "Note: If some files were not replicated, it might be because replication is still in progress."
echo "You can run this script again after a few minutes to check again."
