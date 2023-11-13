#!/bin/bash

# Store the current working directory
ORIGINAL_DIR=$(pwd)

# Check if a tag is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <TAG>"
    exit 1
fi

TAG="$1"
ZIP_FILE="$TAG.zip"
S3_BUCKET="s3://mcserver-rawfiles/zips/"

# Change to the script's directory
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Archive the script's directory
sudo zip -r "$ZIP_FILE" .

# Check if zip command was successful
if [ $? -ne 0 ]; then
    echo "Error: Zip command failed."
    exit 1
fi

# Copy the zip file to S3 bucket
aws s3 cp "$ZIP_FILE" "$S3_BUCKET$ZIP_FILE"

# Check if aws command was successful
if [ $? -ne 0 ]; then
    echo "Error: AWS S3 copy failed."
    exit 1
fi

# Return to the original working directory
cd "$ORIGINAL_DIR" || exit 1

echo "Deployment successful."
