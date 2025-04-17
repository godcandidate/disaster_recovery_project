#!/bin/bash

# Script to test the Lambda function in the primary region
# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get the Lambda function name from Terraform outputs
echo -e "${YELLOW}Getting Lambda function information from Terraform...${NC}"
cd /home/edward/Desktop/Labs_Repo/devops_labs/disaster_recovery_project/environments/primary

LAMBDA_FUNCTION_NAME=$(terraform output -raw lambda_function_name)
REGION=$(terraform output -raw region)

if [ -z "$LAMBDA_FUNCTION_NAME" ]; then
  echo -e "${RED}Failed to get Lambda function name from Terraform outputs.${NC}"
  echo "Make sure you have applied the Terraform configuration and the outputs are available."
  exit 1
fi

echo -e "${GREEN}Lambda function: ${LAMBDA_FUNCTION_NAME} (${REGION})${NC}"

# Invoke the Lambda function
echo -e "${YELLOW}Invoking Lambda function...${NC}"
RESPONSE_FILE="/tmp/lambda_response.json"

aws lambda invoke \
  --function-name $LAMBDA_FUNCTION_NAME \
  --region $REGION \
  --payload '{}' \
  $RESPONSE_FILE

if [ $? -eq 0 ]; then
  echo -e "${GREEN}Lambda function invoked successfully!${NC}"
  
  # Display the response
  echo -e "${YELLOW}Lambda function response:${NC}"
  cat $RESPONSE_FILE | jq '.'
  
  # Clean up
  rm $RESPONSE_FILE
else
  echo -e "${RED}Failed to invoke Lambda function.${NC}"
  exit 1
fi

# Get the CloudWatch logs for the Lambda function
echo -e "${YELLOW}Fetching CloudWatch logs for the Lambda function...${NC}"
LOG_GROUP_NAME="/aws/lambda/$LAMBDA_FUNCTION_NAME"

# Get the latest log stream
LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name $LOG_GROUP_NAME \
  --region $REGION \
  --order-by LastEventTime \
  --descending \
  --limit 1 \
  --query 'logStreams[0].logStreamName' \
  --output text)

if [ -z "$LOG_STREAM" ] || [ "$LOG_STREAM" == "None" ]; then
  echo -e "${RED}No log streams found for the Lambda function.${NC}"
else
  echo -e "${GREEN}Latest log stream: ${LOG_STREAM}${NC}"
  
  # Get the logs from the log stream
  echo -e "${YELLOW}Latest logs:${NC}"
  aws logs get-log-events \
    --log-group-name $LOG_GROUP_NAME \
    --log-stream-name "$LOG_STREAM" \
    --region $REGION \
    --limit 20 \
    --query 'events[*].message' \
    --output text
fi

echo -e "${GREEN}Lambda function test completed!${NC}"
