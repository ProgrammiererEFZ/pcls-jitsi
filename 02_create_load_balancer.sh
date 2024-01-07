#!/bin/bash

# Define variables
VPC_NAME="jitsi-vpc"
SECURITY_GROUP_NAME="jitsi-security-group"
TARGET_GROUP_NAME="jitsi-target"
LOAD_BALANCER_NAME="jitsi-lb"
CERTIFICATE_DOMAIN_NAME="meet.xn--rotzlffel-47a.ch"

echo "Creating ALB with existing VPC, Subnets and Security Group..."

# Retrieve VPC ID
vpc_id=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$VPC_NAME" \
  --query 'Vpcs[0].VpcId' \
  --output text)

# Retrieve subnet IDs
subnet_ids=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$vpc_id" \
  --query 'Subnets[*].SubnetId' \
  --output text)

# Retrieve Security Group ID
security_group_id=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$vpc_id" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Create Application Load Balancer
load_balancer_arn=$(aws elbv2 create-load-balancer \
  --name "$LOAD_BALANCER_NAME" \
  --subnets $subnet_ids \
  --security-groups "$security_group_id" \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)

echo "ALB has been configured."

echo "Creating Listener with existing ACM and Target Group..."

# Retrieve ACM Certificate ARN
certificate_arn=$(aws acm list-certificates \
  --query "CertificateSummaryList[?DomainName=='$CERTIFICATE_DOMAIN_NAME'].CertificateArn" \
  --output text)

# Retrieve Target Group ARN
target_group_arn=$(aws elbv2 describe-target-groups \
  --names "$TARGET_GROUP_NAME" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Create HTTPS Listener with a forward action to the target group
listener_arn=$(aws elbv2 create-listener \
  --load-balancer-arn "$load_balancer_arn" \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn="$certificate_arn" \
  --default-actions Type=forward,TargetGroupArn="$target_group_arn" \
  --query 'Listeners[0].ListenerArn' \
  --output text)

echo "Listener has been configured."

echo "Application Load Balancer with single target group has been configured. Create DNS CNAME:"
aws elbv2 describe-load-balancers --load-balancer-arns "$load_balancer_arn" --query 'LoadBalancers[0].DNSName' --output text
