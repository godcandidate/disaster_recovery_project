#!/bin/bash

# Script to package Lambda function with dependencies
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Create a temporary directory for packaging
TEMP_DIR=$(mktemp -d)
echo "Created temporary directory: $TEMP_DIR"

# Install dependencies to the temporary directory
echo "Installing dependencies..."
pip install -r requirements.txt -t "$TEMP_DIR" --no-cache-dir

# Copy the Lambda function code to the temporary directory
echo "Copying Lambda function code..."
cp tasks_due_tomorrow.py "$TEMP_DIR"

# Create a zip file
cd "$TEMP_DIR"
echo "Creating zip file..."
zip -r lambda_function.zip .

# Move the zip file to the original directory
mv lambda_function.zip "$SCRIPT_DIR"

# Clean up
cd "$SCRIPT_DIR"
rm -rf "$TEMP_DIR"

echo "Lambda function packaged successfully: $SCRIPT_DIR/lambda_function.zip"
