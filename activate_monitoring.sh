#!/bin/bash

# Variablen definieren
email_address="luca.plozner@students.fhnw.ch"
topic_name="EC2InstanceStateChangeNotification"
rule_name="EC2InstanceStateChangeRule"

# SNS-Topic erstellen
topic_arn=$(aws sns create-topic --name "$topic_name" --query 'TopicArn' --output text)
echo "SNS-Topic erstellt: $topic_arn"

# E-Mail-Adresse abonnieren
subscription_output=$(aws sns subscribe --topic-arn "$topic_arn" --protocol email --notification-endpoint "$email_address")
echo "E-Mail-Adresse abonniert: $subscription_output"

# CloudWatch-Alarmregel erstellen
rule_arn=$(aws events put-rule --name "$rule_name" --event-pattern "{\"source\":[\"aws.ec2\"],\"detail-type\":[\"EC2 Instance State-change Notification\"],\"detail\":{\"state\":[\"terminated\"]}}" --query 'RuleArn' --output text)
echo "CloudWatch-Alarmregel erstellt: $rule_arn"

# Zielzuordnung für das SNS-Topic erstellen
target_output=$(aws events put-targets --rule "$rule_name" --targets "Id"="1","Arn"="$topic_arn")
echo "Ziel für Alarmregel festgelegt: $target_output"

echo "Skript abgeschlossen. Bitte überprüfen Sie Ihre E-Mail-Adresse, um das SNS-Abonnement zu bestätigen."
