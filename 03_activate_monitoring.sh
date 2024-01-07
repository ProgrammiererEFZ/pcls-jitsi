#!/bin/bash

# Variablen definieren
EMAIL_ADDRESSES=(
  "luca.plozner@students.fhnw.ch"
  "julie.engel@students.fhnw.ch"
)
MONITORING_TOPIC_NAME="EC2InstanceStateChangeNotification"
MONITORING_RULE_NAME="EC2InstanceStateChangeRule"

# Create SNS topic for EC2 monitoring
topic_arn=$(aws sns create-topic --name "$MONITORING_TOPIC_NAME" --query 'TopicArn' --output text)
echo "Created SNS topic: $topic_arn"

# Create SNS subscriptions for the topic
for email_address in "${EMAIL_ADDRESSES[@]}"; do
  echo "Subscribed $email_address: $(aws sns subscribe --topic-arn "$topic_arn" --protocol email --notification-endpoint "$email_address")"
done

# Create CloudWatch alarm rule
rule_arn=$(aws events put-rule --name "$MONITORING_RULE_NAME" --event-pattern "{\"source\":[\"aws.ec2\"],\"detail-type\":[\"EC2 Instance State-change Notification\"],\"detail\":{\"state\":[\"terminated\"]}}" --query 'RuleArn' --output text)
echo "Created CloudWatch alarm: $rule_arn"

# Create target assignment for SNS topic
target_output=$(aws events put-targets --rule "$MONITORING_RULE_NAME" --targets "Id"="1","Arn"="$topic_arn")
echo "Ziel für Alarmregel festgelegt: $target_output"

echo "Script completed. Please check your email inbox to confirm the SNS subscription."