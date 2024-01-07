#!/bin/bash
set -e

# TODO: cleanup / add uninstalling

# this will create the jitsi policy and user and generate access keys as well an ec2 key pair
POLICY_NAME=test-jitsi-policy2
USER_NAME=test-jitsi-user2
KEY_PAIR_NAME=jitsi-cluster-key

aws iam create-policy --policy-name "$POLICY_NAME" --policy-document file://resources/policy.json > output/jitsi-policy.json
aws iam create-user --user-name "$USER_NAME" > output/jitsi-user.json

aws iam attach-user-policy --user-name "$USER_NAME" --policy-arn $(aws iam list-policies --query 'Policies[?PolicyName==`'"$POLICY_NAME"'`].Arn' --output text)

aws iam create-access-key --user-name "$USER_NAME" > output/jitsi-user-credentials.json
aws ec2 create-key-pair --key-name "$KEY_PAIR_NAME" --query 'KeyMaterial' --output text > output/jitsi-ec2-cluster-key.pem