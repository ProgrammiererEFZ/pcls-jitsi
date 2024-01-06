#!/bin/bash

# Define variables
vpc_name_prefix=("jitsi-vpc-a" "jitsi-vpc-b")
vpc_cidr=("10.0.0.0/16" "10.1.0.0/16") # CIDR blocks for VPCs
instance_name_prefix=("jitsi-server-a" "jitsi-server-b")
instance_type="t2.micro"
ami="ami-0faab6bdbac9486fb"  # Ubuntu 20.04 LTS in eu-central-1
key_name="jitsi-central-luca" # TODO
user_data_script="jitsi_setup.sh"
security_group_name=("jitsi-security-group-a" "jitsi-security-group-b")

# Function to create a security group within the VPC
create_security_group() {
  local vpc_id="$1"
  local sg_name="$2"
  
  aws ec2 create-security-group \
    --group-name "$sg_name" \
    --description "Jitsi Security Group" \
    --vpc-id "$vpc_id" --output text
}

#Create VPCs
vpc_a_id=$(aws ec2 create-vpc --cidr-block "${vpc_cidr[0]}" --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources "$vpc_a_id" --tags "Key=Name,Value=${vpc_name_prefix[0]}"

vpc_b_id=$(aws ec2 create-vpc --cidr-block "${vpc_cidr[1]}" --query 'Vpc.VpcId' --output text)
aws ec2 create-tags --resources "$vpc_b_id" --tags "Key=Name,Value=${vpc_name_prefix[1]}"

echo "Created VPCs:"
echo "VPC A ID: $vpc_a_id"
echo "VPC B ID: $vpc_b_id"

# Create security groups for each VPC
security_group_a_id=$(create_security_group "$vpc_a_id" "jitsi-security-group-a")
security_group_b_id=$(create_security_group "$vpc_b_id" "jitsi-security-group-b")

echo "Created security groups:"
echo "Security Group A ID: $security_group_a_id"
echo "Security Group B ID: $security_group_b_id"

# Define security group rules (add your rules as needed)
security_group_rules=("tcp/22" "tcp/80" "tcp/443" "tcp/4443" "udp/10000")

# Add inbound rules to the security groups
for sg_id in "$security_group_a_id" "$security_group_b_id"; do
  for rule in "${security_group_rules[@]}"; do
    aws ec2 authorize-security-group-ingress \
      --group-id "$sg_id" \
      --protocol $(echo "$rule" | cut -d'/' -f1) \
      --port $(echo "$rule" | cut -d'/' -f2) \
      --cidr 0.0.0.0/0
  done
done

# Create subnets in each VPC and store their IDs
subnet_a_id=$(aws ec2 create-subnet \
  --availability-zone eu-central-1a \
  --vpc-id "$vpc_a_id" \
  --cidr-block "10.0.0.0/24" \
  --query 'Subnet.SubnetId' \
  --output text)

subnet_b_id=$(aws ec2 create-subnet \
  --availability-zone eu-central-1b \
  --vpc-id "$vpc_b_id" \
  --cidr-block "10.1.0.0/24" \
  --query 'Subnet.SubnetId' \
  --output text)

echo "Created subnets:"
echo "Subnet A ID: $subnet_a_id"
echo "Subnet B ID: $subnet_b_id"

# Launch EC2 instances in different subnets with the correct security group
for i in "${!instance_name_prefix[@]}"; do
  instance_name="${instance_name_prefix[$i]}"
  subnet_id=""
  security_group_id=""

  if [ $i -eq 0 ]; then
    subnet_id="$subnet_a_id"
    security_group_id="$security_group_a_id"
  else
    subnet_id="$subnet_b_id"
    security_group_id="$security_group_b_id"
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
