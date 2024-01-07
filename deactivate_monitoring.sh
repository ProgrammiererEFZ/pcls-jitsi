#!/bin/bash

# Variablen definieren
topic_name="EC2InstanceStateChangeNotification"
rule_name="EC2InstanceStateChangeRule"

# SNS-Topic ARN abrufen
topic_arn=$(aws sns list-topics --query "Topics[?ends_with(TopicArn,':$topic_name')].TopicArn" --output text)
if [ -z "$topic_arn" ]; then
    echo "SNS-Topic nicht gefunden."
    exit 1
fi

# SNS-Abonnements für das Topic entfernen
subscriptions=$(aws sns list-subscriptions-by-topic --topic-arn "$topic_arn" --query 'Subscriptions[].SubscriptionArn' --output text)
for sub in $subscriptions; do
    aws sns unsubscribe --subscription-arn "$sub"
    echo "Abonnement entfernt: $sub"
done

# SNS-Topic löschen
aws sns delete-topic --topic-arn "$topic_arn"
echo "SNS-Topic gelöscht: $topic_arn"

# CloudWatch-Alarmregel entfernen
aws events remove-targets --rule "$rule_name" --ids "1"
aws events delete-rule --name "$rule_name"
echo "CloudWatch-Alarmregel gelöscht: $rule_name"

echo "Monitoring-Ressourcen erfolgreich entfernt."
