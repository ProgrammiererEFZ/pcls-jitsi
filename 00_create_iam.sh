#!/bin/bash

# Define variables
POLICY_NAME="jitsi-policy"
USER_NAME="jitsi-user"
EC2_KEY_NAME="jitsi-ec2-key"

echo "Creating IAM resources..."

aws iam create-policy \
  --policy-name "$POLICY_NAME" \
  --policy-document file://resources/policy.json > output/jitsi-policy.json

echo "IAM Policy $POLICY_NAME created."

aws iam create-user --user-name "$USER_NAME" > output/jitsi-user.json

echo "IAM User $USER_NAME created."

aws iam attach-user-policy \
  --user-name "$USER_NAME" \
  --policy-arn "$(aws iam list-policies --query 'Policies[?PolicyName==`'"$POLICY_NAME"'`].Arn' --output text)"

echo "IAM Policy $POLICY_NAME attached to user $USER_NAME."

aws iam create-access-key --user-name "$USER_NAME" > output/jitsi-user-credentials.json

aws ec2 create-key-pair \
  --key-name "$EC2_KEY_NAME" \
  --query 'KeyMaterial' \
  --output text > output/$EC2_KEY_NAME.pem

echo "Created EC2 key pair $EC2_KEY_NAME"

aws configure set aws_access_key_id "$(jq -r '.AccessKey.AccessKeyId' output/jitsi-user-credentials.json)"
aws configure set aws_secret_access_key "$(jq -r '.AccessKey.SecretAccessKey' output/jitsi-user-credentials.json)"
aws configure set default.region eu-central-1

echo "IAM resources successfully created."