#!/bin/bash

# Define variables
vpc_name="jitsi-vpc"
security_group_name="jitsi-security-group"
load_balancer_name="jitsi-lb"
certificate_domain="meet.xn--rotzlffel-47a.ch"
target_group_name="jitsi-target" # Assuming single target group name

# Retrieve VPC ID
vpc_id=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$vpc_name" \
  --query 'Vpcs[0].VpcId' \
  --output text)

# Retrieve Security Group ID
security_group_id=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=$security_group_name" "Name=vpc-id,Values=$vpc_id" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Retrieve subnet IDs
subnet_ids=$(aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$vpc_id" \
  --query 'Subnets[*].SubnetId' \
  --output text)

# Retrieve ACM Certificate ARN
certificate_arn=$(aws acm list-certificates \
  --query "CertificateSummaryList[?DomainName=='$certificate_domain'].CertificateArn" \
  --output text)

# Retrieve Target Group ARN
target_group_arn=$(aws elbv2 describe-target-groups \
  --names "$target_group_name" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Create Application Load Balancer
load_balancer_arn=$(aws elbv2 create-load-balancer \
  --name "$load_balancer_name" \
  --subnets $subnet_ids \
  --security-groups "$security_group_id" \
  --scheme internet-facing \
  --type application \
  --query 'LoadBalancers[0].LoadBalancerArn' \
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

echo "Application Load Balancer with single target group has been configured. Create DNS CNAME:"
aws elbv2 describe-load-balancers --load-balancer-arns "$load_balancer_arn" --query 'LoadBalancers[0].DNSName' --output text
