#!/bin/bash

# Define variables
vpc_name="jitsi-vpc"
vpc_cidr="10.0.0.0/16" # CIDR block for VPC
instance_name_prefix=("jitsi-server-a" "jitsi-server-b")
instance_type="t2.micro"
ami="ami-0faab6bdbac9486fb"  # Ubuntu 20.04 LTS in eu-central-1
key_name="jitsi-central-luca" # TODO use generated key
user_data_script="jitsi_setup.sh"
security_group_name="jitsi-security-group"

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

# Create subnets in different AZs
subnet_a_id=$(aws ec2 create-subnet \
  --availability-zone eu-central-1a \
  --vpc-id "$vpc_id" \
  --cidr-block "10.0.0.0/24" \
  --query 'Subnet.SubnetId' \
  --output text)

subnet_b_id=$(aws ec2 create-subnet \
  --availability-zone eu-central-1b \
  --vpc-id "$vpc_id" \
  --cidr-block "10.0.1.0/24" \
  --query 'Subnet.SubnetId' \
  --output text)

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

# Launch EC2 instances in different subnets with the correct security group
for i in "${!instance_name_prefix[@]}"; do
  instance_name="${instance_name_prefix[$i]}"
  subnet_id=""

  if [ $i -eq 0 ]; then
    subnet_id="$subnet_a_id"
  else
    subnet_id="$subnet_b_id"
  fi

  # Launch EC2 instance
  instance_id=$(aws ec2 run-instances \
    --image-id "$ami" \
    --instance-type "$instance_type" \
    --subnet-id "$subnet_id" \
    --key-name "$key_name" \
    --security-group-ids "$security_group_id" \
    --user-data file://"$user_data_script" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]" \
    --associate-public-ip-address \
    --query 'Instances[0].InstanceId' \
    --output text)

  echo "Launched EC2 instance $instance_name with Instance ID $instance_id in subnet $subnet_id."
done

echo "EC2 instances have been created in different subnets and AZs."

# Create target groups for the EC2 instances
target_group_name_a="jitsi-target-a"
target_group_name_b="jitsi-target-b"

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

# Retrieve instance IDs
instance_a_id=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${instance_name_prefix[0]}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

instance_b_id=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=${instance_name_prefix[1]}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
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