#!/bin/bash
set -e

CLUSTER_NAME=jitsi-cluster-luca
LAUNCH_TYPE=EC2
DEFAULT_REGION=eu-central-1
PROFILE_NAME=jitsi
KEY_PAIR_NAME=jitsi-central-luca

### load jitisi credentials



### setup ECS

ecs-cli configure profile --profile-name "$PROFILE_NAME" --access-key "$AWS_ACCESS_KEY_ID" --secret-key "$AWS_SECRET_ACCESS_KEY"
ecs-cli configure --cluster "$CLUSTER_NAME" --default-launch-type "$LAUNCH_TYPE" --region "$DEFAULT_REGION" --config-name "$PROFILE_NAME"

ecs-cli up \
    --keypair $KEY_PAIR_NAME  \
    --capability-iam \
    --size 1 \
    --launch-type EC2 \
    --instance-type m4.large \
    --tags project=jitsi-cluster,owner=pcls-jitsi \
    --cluster-config "$PROFILE_NAME" \
    --ecs-profile "$PROFILE_NAME"

# the main problem was that the task definition was missing passwords

aws ecs register-task-definition --cli-input-json file://resources/taskdefinition.json
# FIXME: to get the task definition, run: aws ecs list-task-definitions
aws ecs run-task --cluster "$CLUSTER_NAME" --task-definition "arn:aws:ecs:eu-central-1:985487075872:task-definition/docker-jitsi-meet-luca:1" --count 1


## still TODO: somehow the networking does not work
#We will now update the networking. From this screen, click on the Create New Revision again. Scroll down to the area Container Definitions again. Click on JVB.
#Scroll down to the Network Settings and in the box called Links enter prosody:xmpp.meet.jitsi and then click on Update.
# Repeat this for the Jifoco and Web containers.
# Select the Prosody container, and scroll down to the Network settings, and this time enter xmpp.meet.jitsi in the Hostname and then click on Update.
# Scroll to the bottom of the screen and click on Create. You should get a green box that says you have created a new revision of the task.

# things to do:
# - certificates
# - domain setup
# - load balancing (rn it seems it only uses 1 instance instead of both) & autoscaling
# - cleanup --> all the stuff should be somehow automatically torn down