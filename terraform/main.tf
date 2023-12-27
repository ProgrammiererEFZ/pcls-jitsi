provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      Terraform = "true"
      Name      = "pcls-jitsi-terraform"
    }
  }
}

# iam configuration

resource "aws_iam_policy" "jitsi-policy" {
  name   = "jitsi-access-policy"
  policy = data.aws_iam_policy_document.jitsi-policy.json
}

resource "aws_iam_user" "jitsi-user" {
  name = "my-iam-user"
}

resource "aws_iam_user_policy_attachment" "attach_policy" {
  user       = aws_iam_user.jitsi-user.name
  policy_arn = aws_iam_policy.jitsi-policy.arn
}

# security group configuration

resource "aws_security_group" "allow_connections_jitsi-meet" {
  name        = "allow_connections_jitsi-meet"
  ingress {
    from_port   = 10000
    to_port     = 10000
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_connections_jitsi-meet"
  }
}

// ecs configuration

resource "aws_ecs_cluster" "jitsi-central" {
  name = "jitsi-central"
}

resource "aws_ecs_task_definition" "jitsi-task" {
  family                = "jitsi-task"
  container_definitions = file("data_taskdefinition.json")
  requires_compatibilities = ["EC2"]
}

resource "aws_ecs_service" "jitsi-service" {
  name            = "jitsi-service"
  cluster         = aws_ecs_cluster.jitsi-central.id
  task_definition = aws_ecs_task_definition.jitsi-task.arn
  launch_type     = "EC2"
}

resource "aws_launch_configuration" "jitsi-launch-config" {
  name                 = "jitsi-launch-config"
  image_id             = "ami-0630e81a78b8aa3cf"
  instance_type        = "m4.xlarge"
  # security_groups      = ["<your-security-group-id>"]
  # key_name             = aws_key_pair.jitsi-central.key_name
  # iam_instance_profile = "<your-iam-instance-profile>"
}

# resource "aws_autoscaling_group" "jitsi-autoscaling-group" {
#   desired_capacity     = 1
#   max_size             = 1
#   min_size             = 1
#   launch_configuration = aws_launch_configuration.jitsi-launch-config.id
#   vpc_zone_identifier  = ["<your-subnet-ids>"]
# }
