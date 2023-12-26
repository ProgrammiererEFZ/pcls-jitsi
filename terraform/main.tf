provider "aws" {
  region = "eu-central-1"
  # Add any additional authentication or credentials configuration here if needed
}

resource "aws_ecs_cluster" "jitsi-central" {
  name = "jitsi-central"
  # Add any additional cluster configuration here if needed
}

resource "aws_ecs_task_definition" "jitsi-task" {
  // TODO: Add container definitions
  family = "jitsi-task"
}

resource "aws_ecs_service" "jitsi-service" {
  name            = "jitsi-service"
  cluster         = aws_ecs_cluster.jitsi-central.id
  task_definition = aws_ecs_task_definition.jitsi-task.arn
  launch_type     = "EC2"

  # Additional configurations can be added here such as network_configuration, deployment_configuration, etc.
}

resource "aws_ec2_key_pair" "jitsi-central" {
  key_name = "jitsi-central"
  # Add key pair configuration if needed
}

resource "aws_launch_configuration" "jitsi-launch-config" {
  name                 = "jitsi-launch-config"
  image_id             = "ami-xxxxxxxx"  # Replace this with your desired AMI ID
  instance_type        = "m4.xlarge"
  security_groups      = ["<your-security-group-id>"]
  key_name             = aws_ec2_key_pair.jitsi-central.key_name
  iam_instance_profile = "<your-iam-instance-profile>"
  # Add any additional launch configuration parameters here
}

resource "aws_autoscaling_group" "jitsi-autoscaling-group" {
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  launch_configuration = aws_launch_configuration.jitsi-launch-config.id
  vpc_zone_identifier  = ["<your-subnet-ids>"]
  # Add any additional autoscaling group configuration here
}
