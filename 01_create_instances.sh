#!/bin/bash

# Define variables
vpc_name="jitsi-vpc"
vpc_cidr="10.0.0.0/16" # CIDR block for VPC
instance_type="t2.micro"
ami="ami-0faab6bdbac9486fb"  # Ubuntu in eu-central-1
key_name="jitsi-central-luca" # TODO use generated keys
user_data_script="jitsi_setup.sh"
security_group_name="jitsi-security-group"
auto_scaling_group_name="jitsi-auto-scaling-group"
# Function to create a security group within the VPC
create_security_group() {
  local vpc_id="$1"
  local sg_name="$2"
  
  aws ec2 create-security-group \
    --group-name "$sg_name" \
    --description "Jitsi Security Group" \
    --vpc-id "$vpc_id" --output text
}

# Create VPC
vpc_id=$(aws ec2 create-vpc --cidr-block "$vpc_cidr" --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources "$vpc_id" --tags "Key=Name,Value=$vpc_name"

# Create and attach Internet Gateway (IGW) to the VPC
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id"

# Create security group for VPC
security_group_id=$(create_security_group "$vpc_id" "$security_group_name")

# Add inbound rules to the security group
security_group_rules=("tcp/22" "tcp/80" "tcp/443" "tcp/4443" "udp/10000")
for rule in "${security_group_rules[@]}"; do
  aws ec2 authorize-security-group-ingress \
    --group-id "$security_group_id" \
    --protocol $(echo "$rule" | cut -d'/' -f1) \
    --port $(echo "$rule" | cut -d'/' -f2) \
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
  
# Create target groups for the EC2 instances
target_group_name="jitsi-target"

# Create Target Group
target_group_id=$(aws elbv2 create-target-group \
  --name "$target_group_name" \
  --protocol HTTPS \
  --port 443 \
  --vpc-id "$vpc_id" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)


# Define Launch Template variables
launch_template_name="jitsi-launch-template"

# Base64 encode the user data script without newlines
user_data_base64=$(base64 -w 0 "$user_data_script")


# Create Launch Template for Auto Scaling Group
aws ec2 create-launch-template \
  --launch-template-name "$launch_template_name" \
  --version-description "Version1" \
  --launch-template-data "{\"ImageId\":\"$ami\",\"InstanceType\":\"$instance_type\",\"KeyName\":\"$key_name\",\"UserData\":\"$user_data_base64\",\"NetworkInterfaces\":[{\"DeviceIndex\":0,\"AssociatePublicIpAddress\":true,\"Groups\":[\"$security_group_id\"]}]}"

# Create Auto Scaling Group using Launch Template
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name "$auto_scaling_group_name" \
  --launch-template "LaunchTemplateName=$launch_template_name,Version=1" \
  --min-size 1 \
  --max-size 1 \
  --desired-capacity 1 \
  --vpc-zone-identifier "$subnet_a_id,$subnet_b_id" \
  --health-check-type EC2 \
  --health-check-grace-period 200 \
  --target-group-arns "$target_group_id" \
  --tags "Key=Name,Value=jitsi-server"

echo "Auto Scaling Group has been configured."