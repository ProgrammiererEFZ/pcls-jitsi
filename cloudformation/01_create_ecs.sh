#!/bin/bash
set -e

CLUSTER_NAME=jitsi-cluster
LAUNCH_TYPE=EC2
PROFILE_NAME=jitsi

ecs-cli configure profile --profile-name "$PROFILE_NAME" --access-key "$AWS_ACCESS_KEY_ID" --secret-key "$AWS_SECRET_ACCESS_KEY"
ecs-cli configure --cluster "$CLUSTER_NAME" --default-launch-type "$LAUNCH_TYPE" --region "$AWS_DEFAULT_REGION" --config-name "$PROFILE_NAME"

KEY_PAIR_NAME=jitsi-cluster
aws ec2 create-key-pair --key-name "$KEY_PAIR_NAME" --query 'KeyMaterial' --output text > cluster-key.pem

ecs-cli up \
    --keypair $KEY_PAIR_NAME  \
    --capability-iam \
    --size 2 \
    --launch-type EC2 \
    --instance-type m4.xlarge \
    --tags project=jitsi-cluster,owner=pcls-jitsi \
    --cluster-config "$PROFILE_NAME" \
    --ecs-profile "$PROFILE_NAME"

# ecs-cli compose --project-name tutorial  --file docker-compose.yml --debug service up 
aws ecs register-task-definition --cli-input-json file://docker-jitsi-meet-taskdefinition.json
aws ecs run-task --cluster "$CLUSTER_NAME" --task-definition docker-jitsi-meet:1 --count 1