#!/bin/bash

# Define variables
vpc_name="jitsi-vpc"
target_group_name_a="jitsi-target-a"
target_group_name_b="jitsi-target-b"
instance_name_a="jitsi-server-a"
instance_name_b="jitsi-server-b"
security_group_name="jitsi-security-group"
load_balancer_name="jitsi-lb"
certificate_domain="meet.xn--rotzlffel-47a.ch"

# Retrieve VPC ID using VPC name
vpc_id=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=$vpc_name" \
  --query 'Vpcs[0].VpcId' \
  --output text)

# Create Target Group A
target_group_a_id=$(aws elbv2 create-target-group \
  --name "$target_group_name_a" \
  --protocol HTTPS \
  --port 443 \
  --vpc-id "$vpc_id" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Create Target Group B
target_group_b_id=$(aws elbv2 create-target-group \
  --name "$target_group_name_b" \
  --protocol HTTPS \
  --port 443 \
  --vpc-id "$vpc_id" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

# Retrieve instance ID using instance name
instance_a_id=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$instance_name_a" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

instance_b_id=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=$instance_name_b" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text)

# Register instance A with Target Group A
aws elbv2 register-targets \
  --target-group-arn "$target_group_a_id" \
  --targets Id="$instance_a_id"

# Register instance B with Target Group B
aws elbv2 register-targets \
  --target-group-arn "$target_group_b_id" \
  --targets Id="$instance_b_id"

echo "Target groups and instances have been configured."
