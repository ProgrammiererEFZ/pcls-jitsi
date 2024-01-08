#!/bin/bash

# Define variables
VPC_NAME="jitsi-vpc"
SECURITY_GROUP_NAME="jitsi-security-group"
TARGET_GROUP_NAME="jitsi-target"
AUTOSCALING_GROUP_NAME="jitsi-auto-scaling-group"
LAUNCH_TEMPLATE_NAME="jitsi-launch-template"
LOAD_BALANCER_NAME="jitsi-lb"
MONITORING_TOPIC_NAME="EC2InstanceStateChangeNotification"
MONITORING_RULE_NAME="EC2InstanceStateChangeRule"
policy_name="jitsi-policy"
user_name="jitsi-user"
ec2_key_name="jitsi-ec2-key"

echo "--- Deleting monitoring resources..."

# Get SNS-Topic ARN
topic_arn=$(aws sns list-topics --query "Topics[?ends_with(TopicArn,':$MONITORING_TOPIC_NAME')].TopicArn" --output text)
if [ -z "$topic_arn" ]; then
    echo "SNS-Topic not found."
    exit 1
fi

# Remove SNS-Subscriptions for SNS Topic
subscriptions=$(aws sns list-subscriptions-by-topic --topic-arn "$topic_arn" --query 'Subscriptions[].SubscriptionArn' --output text)
for sub in $subscriptions; do
    aws sns unsubscribe --subscription-arn "$sub"
    echo "Removed SNS subscription: $sub"
done

# Delete SNS-Topic
aws sns delete-topic --topic-arn "$topic_arn"
echo "Deleted SNS-Topic: $topic_arn"

# Delete CloudWatch-Alarmregel
aws events remove-targets --rule "$MONITORING_RULE_NAME" --ids "1"
aws events delete-rule --name "$MONITORING_RULE_NAME"
echo "Deleted CloudWatch rule: $MONITORING_RULE_NAME"

echo "--- Monitoring resources successfully deleted."

echo "--- Deleting Auto-Scaling Group, Load Balancer, Target Group, Launch Template and VPC Setup..."

# Delete Auto Scaling Group
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name "$AUTOSCALING_GROUP_NAME" --force-delete
echo "Auto Scaling Group $AUTOSCALING_GROUP_NAME deleted."

# Delete Load Balancer
aws elbv2 delete-load-balancer --load-balancer-arn "$(aws elbv2 describe-load-balancers --names "$LOAD_BALANCER_NAME" --query 'LoadBalancers[0].LoadBalancerArn' --output text)"
echo "Load Balancer deleted. WAIT 10 SECONDS"
sleep 10

# Delete Target Group
aws elbv2 delete-target-group --target-group-arn "$(aws elbv2 describe-target-groups --names "$TARGET_GROUP_NAME" --query 'TargetGroups[0].TargetGroupArn' --output text)"
echo "Target Group deleted."

# Delete Launch Template
aws ec2 delete-launch-template --launch-template-name "$LAUNCH_TEMPLATE_NAME"
echo "Launch Template deleted."

# Delete VPC only after all EC2 instances are terminated
while [ "$(aws ec2 describe-instances --filters "Name=vpc-id,Values=$vpc_id" "Name=instance-state-name,Values=terminated" --query 'Reservations[*].Instances[*].InstanceId' --output text)" != "" ]
do
  # Wait for 30 seconds and check again if any instance is still not terminated
  echo "Waiting for all instances to be terminated..."
  sleep 30
done

# Retrieve VPC ID
vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Vpcs[0].VpcId' --output text)

# Delete Subnets
for subnet_id in $(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[].SubnetId' --output text); do
    aws ec2 delete-subnet --subnet-id "$subnet_id"
    echo "Deleted subnet: $subnet_id"
done

# Detach and Delete Internet Gateway
for igw_id in $(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[].InternetGatewayId' --output text); do
    aws ec2 detach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id"
    aws ec2 delete-internet-gateway --internet-gateway-id "$igw_id"
    echo "Detached and deleted internet gateway: $igw_id"
done

# Delete custom route tables associated with the VPC
for rt_id in $(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpc_id" "Name=association.main,Values=false" --query 'RouteTables[].RouteTableId' --output text); do
    aws ec2 delete-route-table --route-table-id "$rt_id"
    echo "Deleted route table: $rt_id"
done

# Delete Security Group
security_group_id=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SECURITY_GROUP_NAME" "Name=vpc-id,Values=$vpc_id" --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 delete-security-group --group-id "$security_group_id"
echo "Security Group deleted."


# Delete VPC
aws ec2 delete-vpc --vpc-id "$vpc_id"
echo "VPC deleted."


# Delete IAM Policy
policy_arn=$(aws iam list-policies --query 'Policies[?PolicyName==`'"$policy_name"'`].Arn' --output text)

# Detach the policy from the user
aws iam detach-user-policy --user-name "$user_name" --policy-arn "$policy_arn"

# Delete all non-default versions of the policy
policy_versions=$(aws iam list-policy-versions --policy-arn "$policy_arn" --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text)
for version in $policy_versions; do
    aws iam delete-policy-version --policy-arn "$policy_arn" --version-id "$version"
done

# Delete the policy
aws iam delete-policy --policy-arn "$policy_arn"
echo "IAM Policy deleted."

# Delete IAM User
user_arn=$(aws iam list-users --query 'Users[?UserName==`'"$user_name"'`].Arn' --output text)
aws iam delete-access-key --access-key-id "$(aws iam list-access-keys --user-name "$user_name" --query 'AccessKeyMetadata[0].AccessKeyId' --output text)" --user-name "$user_name"
aws iam delete-user --user-name "$user_name"
echo "IAM User deleted."

# Delete EC2 Key Pair
aws ec2 delete-key-pair --key-name "$ec2_key_name"
rm -f output/$ec2_key_name.pem
echo "EC2 Key Pair deleted."

echo "IAM resources successfully deleted."

