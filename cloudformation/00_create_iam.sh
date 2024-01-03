#!/bin/bash
set -e

# this will create the jitsi policy and user

aws iam create-policy --policy-name jitsi-policy --policy-document file://resources/policy.json
aws iam create-user --user-name jitsi-user

# maybe we have to run aws iam list-policies first to get the arn
aws iam attach-user-policy --user-name jitsi-user --policy-arn arn:aws:iam::your-account-id:policy/jitsi-policy

aws iam create-access-key --user-name jitsi-user > output/jitsi-user-credentials.json