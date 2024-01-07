#!/bin/bash

# Define variables
vpc_name="jitsi-vpc"
security_group_name="jitsi-security-group"
auto_scaling_group_name="jitsi-auto-scaling-group"
load_balancer_name="jitsi-lb"
target_group_name="jitsi-target"
launch_template_name="jitsi-launch-template"

# Retrieve Auto Scaling Group
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "$auto_scaling_group_name" --force-delete
echo "Auto Scaling Group deleted."

# Retrieve Target Group ARN
target_group_arn=$(aws elbv2 describe-target-groups --names "$target_group_name" --query 'TargetGroups[0].TargetGroupArn' --output text)

# Retrieve Load Balancer ARN
load_balancer_arn=$(aws elbv2 describe-load-balancers --names "$load_balancer_name" --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Delete Load Balancer
aws elbv2 delete-load-balancer --load-balancer-arn "$load_balancer_arn"
echo "Load Balancer deleted. WAIT 10 SECONDS"
sleep 10

# Delete Target Group
aws elbv2 delete-target-group --target-group-arn "$target_group_arn"
echo "Target Group deleted."

# Delete Launch Template
aws ec2 delete-launch-template --launch-template-name "$launch_template_name"
echo "Launch Template deleted."



# Finally, delete the VPC
#aws ec2 delete-vpc --vpc-id "$vpc_id"
#echo "VPC deleted."

#To delete vpc, ec2 instances need to be shut down completly which takes time
echo "DELETE VPC MANUALLY!!!!!!!"
