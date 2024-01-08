#!/bin/bash

# Define variables
VPC_NAME="jitsi-vpc"
SECURITY_GROUP_NAME="jitsi-security-group"
TARGET_GROUP_NAME="jitsi-target"
AUTOSCALING_GROUP_NAME="jitsi-auto-scaling-group"
LAUNCH_TEMPLATE_NAME="jitsi-launch-template"

# Params for EC2 setup
EC2_USER_DATA_SCRIPT="resources/jitsi_setup.sh"
EC2_AMI="EC2_AMI-0faab6bdbac9486fb"  # Ubuntu in eu-central-1
EC2_INSTANCE_TYPE="t2.micro"   # Free tier, adjust to your needs
EC2_KEY_NAME="jitsi-ec2-key"

# Function to create a security group within the VPC
create_security_group() {
  local vpc_id="$1"
  local sg_name="$2"
  
  aws ec2 create-security-group \
    --group-name "$sg_name" \
    --description "Jitsi Security Group" \
    --vpc-id "$vpc_id" --output text
}

echo "Creating VPC with Internet Gateway and Security Group..."

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block "10.0.0.0/16" --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources "$vpc_id" --tags "Key=Name,Value=$VPC_NAME"

# Create and attach Internet Gateway (IGW) to the VPC
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id"

# Create security group for VPC
security_group_id=$(create_security_group "$vpc_id" "$SECURITY_GROUP_NAME")

# Add inbound rules to the security group
security_group_rules=("tcp/22" "tcp/80" "tcp/443" "tcp/4443" "udp/10000")
for rule in "${security_group_rules[@]}"; do
  aws ec2 authorize-security-group-ingress \
    --group-id "$security_group_id" \
    --protocol "$(echo "$rule" | cut -d'/' -f1)" \
    --port "$(echo "$rule" | cut -d'/' -f2)" \
    --cidr 0.0.0.0/0
done

# Create subnets in different AZs with auto-assign public IP enabled
subnet_a_id=$(aws ec2 create-subnet \
  --availability-zone eu-central-1a \
  --vpc-id "$vpc_id" \
  --cidr-block "10.0.0.0/24" \
  --query 'Subnet.SubnetId' \
  --output text)
aws ec2 modify-subnet-attribute --subnet-id "$subnet_a_id" --map-public-ip-on-launch

subnet_b_id=$(aws ec2 create-subnet \
  --availability-zone eu-central-1b \
  --vpc-id "$vpc_id" \
  --cidr-block "10.0.1.0/24" \
  --query 'Subnet.SubnetId' \
  --output text)
aws ec2 modify-subnet-attribute --subnet-id "$subnet_b_id" --map-public-ip-on-launch

# Get the main route table associated with the VPC
main_route_table_id=$(aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$vpc_id" "Name=association.main,Values=true" \
  --query 'RouteTables[0].RouteTableId' \
  --output text)

# Create a route in the main route table that points all traffic to the IGW
aws ec2 create-route \
  --route-table-id "$main_route_table_id" \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id "$igw_id"

echo "VPC with Internet Gateway and Security Group has been configured."

echo "Creating Target Group..."

# Create Target Group
target_group_id=$(aws elbv2 create-target-group \
  --name "$TARGET_GROUP_NAME" \
  --protocol HTTPS \
  --port 443 \
  --vpc-id "$vpc_id" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)

echo "Target Group has been configured."

echo "Creating Launch Template..."

# Base64 encode the user data script without newlines
user_data_base64=$(base64 -w 0 "$EC2_USER_DATA_SCRIPT")

# Create Launch Template for Auto Scaling Group
aws ec2 create-launch-template \
  --launch-template-name "$LAUNCH_TEMPLATE_NAME" \
  --version-description "Version1" \
  --launch-template-data "{\"ImageId\":\"$EC2_AMI\",\"InstanceType\":\"$EC2_INSTANCE_TYPE\",\"KeyName\":\"$EC2_KEY_NAME\",\"UserData\":\"$user_data_base64\",\"NetworkInterfaces\":[{\"DeviceIndex\":0,\"AssociatePublicIpAddress\":true,\"Groups\":[\"$security_group_id\"]}]}"

echo "Launch Template has been configured."

echo "Creating Auto Scaling Group..."

# Create Auto Scaling Group using Launch Template
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name "$AUTOSCALING_GROUP_NAME" \
  --launch-template "LaunchTemplateName=$LAUNCH_TEMPLATE_NAME,Version=1" \
  --min-size 1 \
  --max-size 1 \
  --desired-capacity 1 \
  --vpc-zone-identifier "$subnet_a_id,$subnet_b_id" \
  --health-check-type EC2 \
  --health-check-grace-period 200 \
  --target-group-arns "$target_group_id" \
  --tags "Key=Name,Value=jitsi-server"

echo "Auto Scaling Group has been configured."