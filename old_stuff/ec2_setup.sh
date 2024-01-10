#!/bin/bash

# Define variables
instance_name_prefix=("jitsi-server-a" "jitsi-server-b")
instance_type="t2.micro"
ami="ami-0faab6bdbac9486fb"  # Ubuntu 20.04 LTS in eu-central-1
key_name="jitsi-central-luca" # TODO
user_data_script="jitsi_setup.sh"
security_group_name="jitsi-security-group"

# Create security group
aws ec2 create-security-group \
  --group-name "$security_group_name" \
  --description "Jitsi Security Group"

# Define security group rules
security_group_rules=("tcp/22" "tcp/80" "tcp/443" "udp/10000")

# Add inbound rules to the security group
for rule in "${security_group_rules[@]}"; do
  aws ec2 authorize-security-group-ingress \
    --group-name "$security_group_name" \
    --protocol $(echo "$rule" | cut -d'/' -f1) \
    --port $(echo "$rule" | cut -d'/' -f2) \
    --cidr 0.0.0.0/0
done

# Launch EC2 instances in different Availability Zones
for i in "${!instance_name_prefix[@]}"; do
  instance_name="${instance_name_prefix[$i]}"
  availability_zone=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)

  # Launch EC2 instance
  aws ec2 run-instances \
    --image-id "$ami" \
    --instance-type "$instance_type" \
    --placement "AvailabilityZone=$availability_zone" \
    --key-name "$key_name" \
    --security-groups "$security_group_name" \
    --user-data file://"$user_data_script" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]"
done

echo "EC2 instances have been created."
