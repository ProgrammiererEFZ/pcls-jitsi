#!/bin/bash
set -e

CLUSTER_NAME=jitsi-cluster
LAUNCH_TYPE=EC2
DEFAULT_REGION=eu-central-1
PROFILE_NAME=jitsi
KEY_PAIR_NAME=jitsi-cluster-key

### load jitisi credentials

AWS_ACCESS_KEY_ID=$(jq -r '.AccessKey.AccessKeyId' output/jitsi-user-credentials.json)
AWS_SECRET_ACCESS_KEY=$(jq -r '.AccessKey.SecretAccessKey' output/jitsi-user-credentials.json)

### setup security group

for arn in $(aws ecs list-container-instances --cluster "$CLUSTER_NAME" --query 'containerInstanceArns[]' --output text); do
    echo "arn: $arn"
    for instances in $(aws ecs describe-container-instances --cluster "$CLUSTER_NAME" --container-instances "$arn" --query 'containerInstances[].ec2InstanceId' --output text); do
        echo "instance: $instances"
        aws ec2 authorize-security-group-ingress --group-id $(aws ec2 describe-instances --instance-ids "$instances" --query 'Reservations[].Instances[].SecurityGroups[].GroupId' --output text) --protocol udp --port 10000 --cidr 0.0.0.0/0
        aws ec2 authorize-security-group-ingress --group-id $(aws ec2 describe-instances --instance-ids "$instances" --query 'Reservations[].Instances[].SecurityGroups[].GroupId' --output text) --protocol tcp --port 4443 --cidr 0.0.0.0/0
    done
done
