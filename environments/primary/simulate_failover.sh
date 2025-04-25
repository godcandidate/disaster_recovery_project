#!/bin/bash

# Failover Simulation Script for Disaster Recovery Project
# This script simulates a disaster in the primary region by:
# 1. Terminating the AMI builder instance
# 2. Deleting the RDS instance

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print header
echo -e "${YELLOW}=========================================================${NC}"
echo -e "${YELLOW}       DISASTER RECOVERY FAILOVER SIMULATION             ${NC}"
echo -e "${YELLOW}=========================================================${NC}"
echo -e "${RED}WARNING: This script will simulate a disaster by terminating${NC}"
echo -e "${RED}         resources in your primary region. This will cause${NC}"
echo -e "${RED}         downtime and trigger the DR failover process.${NC}"
echo -e "${YELLOW}=========================================================${NC}"

# Confirm execution
read -p "Are you sure you want to continue? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo -e "${GREEN}Failover simulation aborted.${NC}"
    exit 0
fi

# Get resource IDs from Terraform outputs
echo -e "${YELLOW}Fetching resource IDs from Terraform state...${NC}"
DB_INSTANCE_ID=$(terraform output -raw primary_db_instance_id)
AMI_BUILDER_ID=$(terraform output -raw ami_builder_id 2>/dev/null || echo "")

if [[ -z "$DB_INSTANCE_ID" ]]; then
    echo -e "${RED}Error: Could not find RDS instance ID in Terraform outputs.${NC}"
    echo -e "${RED}Make sure you're in the primary environment directory and terraform has been applied.${NC}"
    exit 1
fi

# Terminate AMI builder instance if it exists
if [[ ! -z "$AMI_BUILDER_ID" ]]; then
    echo -e "${YELLOW}Terminating AMI builder instance (ID: $AMI_BUILDER_ID)...${NC}"
    aws ec2 terminate-instances --instance-ids "$AMI_BUILDER_ID"
    echo -e "${GREEN}AMI builder instance termination initiated.${NC}"
else
    echo -e "${YELLOW}No AMI builder instance found. Skipping this step.${NC}"
    echo -e "${YELLOW}You may need to manually terminate the AMI builder instance if it exists.${NC}"
fi

# Delete RDS instance
echo -e "${YELLOW}Deleting RDS instance (ID: $DB_INSTANCE_ID)...${NC}"
aws rds delete-db-instance \
    --db-instance-identifier "$DB_INSTANCE_ID" \
    --skip-final-snapshot

echo -e "${GREEN}RDS instance deletion initiated.${NC}"
echo -e "${YELLOW}=========================================================${NC}"
echo -e "${YELLOW}Failover simulation initiated. The DR environment should${NC}"
echo -e "${YELLOW}automatically detect the failure and begin failover.${NC}"
echo -e "${YELLOW}=========================================================${NC}"
echo -e "${YELLOW}Monitoring failover process...${NC}"

# Wait for EventBridge to detect the changes and trigger the Lambda in DR region
echo -e "${YELLOW}Waiting for EventBridge to detect changes (30 seconds)...${NC}"
sleep 30

echo -e "${GREEN}Failover simulation completed.${NC}"
echo -e "${YELLOW}To check the status of your DR environment, run:${NC}"
echo -e "  cd ../dr && terraform output"
echo -e "${YELLOW}To check if the DR Lambda was triggered, check CloudWatch Logs in the DR region.${NC}"
