# Deploying Jitsi on AWS ECS

## Prerequisites

### Environment

You must install and set up to access your AWS environment: - AWS Account: You will be configuring services, so you need an account with a user that can provision those services. - DNS provider: This is needed to obtain an SSL certificate. You can use Amazon Route 53 or other DNS provider.

You will also need the following tools; make sure they are all the latest versions and up and running before proceeding. - ECS-CLI: Install the AWS ECS client link. - Docker and Docker-compose.

### SSH key pair

Create a key pair that you will use to SSH into your Jitsi server. From the EC2 console, on the left-hand side click on Key Pairs and then use the Create button to create a PEM (default option) key pair. Click on the Create Key Pair button and then make sure you save the key that pops up on your machine. Keep this safe. You will need to change the permissions of this file.

Tip: Key pairs are regional, so make sure you match up the key pair you generate with the region into which you are going to launch your EC2 instances.

## Modify your docker-compose.yml and review .env file

On your workstation, clone the repo in a clean folder:

```bash
$ git clone https://github.com/jitsi/docker-jitsi-meet && cd docker-jitsi-meet
$ cp env.example .env
```

You will now need to edit the docker-compose file and strip out all the Volume lines, so for example

```yaml
networks:
  meet.jitsi: null
  volumes:
    - /home/ubuntu/.jitsi-meet-cfg/jicofo:/config:rw
```

Would become

```yaml
networks:
  meet.jitsi: null
```

(Your volume paths may vary; this was from my output.)

You should review the .env file you have created. The defaults are typically okay for the installation, but you may want to change the values once you have become familiar with the setup.

You now have the necessary source files to begin the proper installation and configuration.

## Creating the ECS cluster

Create your Amazon ECS cluster using the following command. In this example, we will create an ECS cluster called jitsi-central hosted in the eu-central-1 region:

```bash
$ ecs-cli configure --cluster jitsi-central --default-launch-type EC2 --region eu-central-1 --config-name jitsi-central
```

You will not get any output, but if you check your ~/.ecs/ folder, you will have a file that will contain output like the following:

```bash
version: v1
default: jitsi-central
clusters:
jitsi-central:
cluster: jitsi-central
region: eu-central-1
default_launch_type: EC2
```

Now run the following command to create the Cloudformation template and build the cluster. You will see here that we are using an EC2 key pair – this will allow you to SSH into these instances if you need to troubleshoot.

```bash
$ ecs-cli up --keypair jitsi-central --capability-iam --size 1 --instance-type m4.xlarge --launch-type EC2
```

This should generate output like the following:

```bash
INFO[0000] Using recommended Amazon Linux 2 AMI with ECS Agent 1.37.0 and Docker version 18.09.9-ce
INFO[0000] Created cluster cluster=jitsi-central region=eu-central-1
INFO[0001] Waiting for your cluster resources to be created...
INFO[0001] Cloudformation stack status stackStatus=CREATE_IN_PROGRESS
INFO[0061] Cloudformation stack status stackStatus=CREATE_IN_PROGRESS
INFO[0121] Cloudformation stack status stackStatus=CREATE_IN_PROGRESS
VPC created: vpc-0eeacc205a44d937c
Security Group created: sg-08d90fc4ee48edde3
Subnet created: subnet-02ea5c5d22f9692c5
Subnet created: subnet-098b26c7298c21bff
Cluster creation succeeded.
```

You can check your AWS CloudFormation console and you should now see a new stack that has been created for this.

The next step is to create the taskDefinition, which is where you will create the definition for the four containers that make up Jitsi. By default, the taskDefinition takes the directory name, so we will create a directory and move our docker composer file into that first:

```bash
$ mkdir jitsi-central
$ mv docker-jitsi-meet jitsi-central
$ cd jitsi-central/docker-jitsi-meet
$ ecs-cli compose --file docker-compose.yml up
```

And you should get output as follows:

```bash
WARN[0000] Skipping unsupported YAML option for service... option name=depends_on service name=jicofo
WARN[0000] Skipping unsupported YAML option for service... option name=networks service name=jicofo
WARN[0000] Skipping unsupported YAML option for service... option name=depends_on service name=jvb
WARN[0000] Skipping unsupported YAML option for service... option name=networks service name=jvb
WARN[0000] Skipping unsupported YAML option for service... option name=expose service name=prosody
WARN[0000] Skipping unsupported YAML option for service... option name=networks service name=prosody
WARN[0000] Skipping unsupported YAML option for service... option name=networks service name=web
INFO[0000] Using ECS task definition TaskDefinition="jitsi-central:1"
INFO[0000] Starting container... container=55d4770b-d356-447e-b079-c3c743da5e08/jicofo
INFO[0000] Starting container... container=55d4770b-d356-447e-b079-c3c743da5e08/jvb
INFO[0000] Starting container... container=55d4770b-d356-447e-b079-c3c743da5e08/prosody
INFO[0000] Starting container... container=55d4770b-d356-447e-b079-c3c743da5e08/web
INFO[0000] Describe ECS container status container=55d4770b-d356-447e-b079-c3c743da5e08/web desiredStatus=RUNNING lastStatus=PENDING taskDefinition="jitsi-central:1"
INFO[0000] Describe ECS container status container=55d4770b-d356-447e-b079-c3c743da5e08/jvb desiredStatus=RUNNING lastStatus=PENDING taskDefinition="jitsi-central:1"
INFO[0000] Describe ECS container status container=55d4770b-d356-447e-b079-c3c743da5e08/jicofo desiredStatus=RUNNING lastStatus=PENDING taskDefinition="jitsi-central:1"
INFO[0000] Describe ECS container status container=55d4770b-d356-447e-b079-c3c743da5e08/prosody desiredStatus=RUNNING lastStatus=PENDING taskDefinition="jitsi-central:1"
INFO[0012] Describe ECS container status container=55d4770b-d356-447e-b079-c3c743da5e08/web desiredStatus=RUNNING lastStatus=PENDING taskDefinition="jitsi-central:1"
INFO[0012] Describe ECS container status container=55d4770b-d356-447e-b079-c3c743da5e08/jvb desiredStatus=RUNNING lastStatus=PENDING taskDefinition="jitsi-central:1"
INFO[0012] Describe ECS container status container=55d4770b-d356-447e-b079-c3c743da5e08/jicofo desiredStatus=RUNNING lastStatus=PENDING taskDefinition="jitsi-central:1"
INFO[0012] Describe ECS container status container=55d4770b-d356-447e-b079-c3c743da5e08/prosody desiredStatus=RUNNING lastStatus=PENDING taskDefinition="jitsi-central:1"
INFO[0018] Started container... container=55d4770b-d356-447e-b079-c3c743da5e08/web desiredStatus=RUNNING lastStatus=RUNNING taskDefinition="jitsi-central:1"
INFO[0018] Started container... container=55d4770b-d356-447e-b079-c3c743da5e08/jvb desiredStatus=RUNNING lastStatus=RUNNING taskDefinition="jitsi-central:1"
INFO[0018] Started container... container=55d4770b-d356-447e-b079-c3c743da5e08/jicofo desiredStatus=RUNNING lastStatus=RUNNING taskDefinition="jitsi-central:1"
INFO[0018] Started container... container=55d4770b-d356-447e-b079-c3c743da5e08/prosody desiredStatus=RUNNING lastStatus=RUNNING taskDefinition="jitsi-central:1"
```

We now have our taskDefinition for jitsi-central up and running. Now we need to amend configuration options before we can start and then access our Jitsi application.

## Changing the configuration

From the Amazon ECS console, select Task Definition and, from the list, select the task you have just created; in the example above, this will be jitsi-central.

When you click on it, you will see a list of versions of the task. If this is the first, you will only see one, but as you change, edit, configure the tasks, the versioned list will grow, and you will see that each version as the next sequential number added to it—for example, jitsi-central:1, jitsi-central:2, jitsi-central:3, etc.

Click on the newest (highest number) version. On the screen that follows, click on the Create New Revision.

Scroll down to the area called Container Definitions and you should see the four containers: jvb, prosody, web, and jicodo.

### Memory

The first thing we are going to do is change memory allocations as the defaults are too low; you will need to experiment with this for your set up, and tune it depending on how busy your server will be.

Click on JVB. On the screen that pops up, change the Memory Limits (MiB) from the default of 512 to 4096. Click on Update. Change Prosody and change it to 1024 and Jicofo and change it to 1024, making sure you click on Update each time.

When you get this up and running, you might want to modify the memory settings to optimize the performance of the application.

Scroll to the bottom of the screen and click on Create. You should get a green box that says you have created a new revision of the task.

### Networking

We will now update the networking. From this screen, click on the Create New Revision again. Scroll down to the area Container Definitions again. Click on JVB.

Scroll down to the Network Settings and in the box called Links enter prosody:xmpp.meet.jitsi and then click on Update.

Repeat this for the Jifoco and Web containers.

Select the Prosody container, and scroll down to the Network settings, and this time enter xmpp.meet.jitsi in the Hostname and then click on Update.

Scroll to the bottom of the screen and click on Create. You should get a green box that says you have created a new revision of the task.

## Update the running containers

From the Amazon ECS console, click on Clusters and select the jitsi-central (or whatever you have called yours) cluster.

From the screen that comes up, click on Tasks. You should see that revision :1 (or a revision older than what you have just created) is running.

Click on the current, Running task and then select Stop. A warning will appear, but click on Stop. You should now have no more running tasks.

Click on Run New Task. From the next screen, click on the Switch to Launch Type, which will be in small writing and is easily missed.

Select EC2, and then scroll down and select the newest (highest number) revision of the task definition.

Scroll to the bottom and click Run Task. When you return to the Tasks dashboard, the status may be Pending, but it should quickly change to Running.

Click on the running task, which should display a details page, and with your four running containers displayed near the bottom. Click on Web, which will show the public IP address, which is open. However, the security group has blocked these, so they will not work yet.

## Update security group

You will need to amend the security group to allow inbound traffic. Change the security group so that it allows incoming UDP on port 10000 from Any for the container host. To find the security group, look at the EC2 host that is running the ECS containers, and you will find the security group you need to update.

## Add an SSL certificate

You can use AWS Certificate Manager (ACM) to generate an ssl certificate, or you can upload an existing one via your preferred certificate authority (CA).

From the AWS console, launch the ACM (it is under Security, Identity, and Compliance), and then click on Get Started. If you want to use a certificate from your preferred certificate authority, use the Import Certificate and add the key files (in PEM format).

Click on Request a Public Certificate and in the next screen enter the domain you are going to be using to access your Jitsi server. Click on Next.

You will be provided two options for domain validation. If you select DNS, you will need to add a CNAME alias into your existing DNS record (this is pretty standard). If you select email, then the email alias listed in the WHOIS record will be contacted and must respond within a set amount of time. For the purpose if this tutorial, I will select DNS.

In the next screen (Tags) select Review, and then click on Confirm and Request if you are ok with what you have entered.

On the next screen, you will now see the details you need to add in your CNAME record. Click on Continue and you will be taken to the certificate manager console. Your request should now be in Pending Validation. This should now take a few minutes once you have updated your DNS records, and you should see the status change to Issued.

## Configuring a Load Balancer

Before configuring this, make sure you identify the VPC and Subnet information your cluster has been deployed into. You can do this via the EC2 console via the Instances.

From the Amazon EC2 console, select Load Balancers (it appears near the bottom) and then click on Create Load Balancer.

Select Application Load Balancer and click on Create. For name, give it jitsi-lb.

Under Listeners add HTTPS by clicking on Add Listener.

Under Availability zones, select the right VPC and then select two availability zones that your load balancer will work across.

Click on Next Configuration, and from the Configure Security Settings you should now be able to select the certificate you created from the previous step. Click on Configure Security Groups.

Accept the default, and click on Configure Routing. Provide a name jitsi-target leave target type to instance, but change the protocol to HTTPS and the port to 8443. Click on Register Targets.

On the bottom half of the screen (Instances) click on the instance that is the ECS cluster and then click on Add to Registered. Depending on how many hosts you have, you will need to add them all here; in this default tutorial, I only configured one, so I will only add one. Click Review and then Create.

Provisioning the load balancer will take time. When it completes, you will need to take the A Record details and update your DNS so that your host resolves to the load balancer.

Once this has completed, you should configure HTTP to HTTPS redirection from the load balancer. Select the load balancer you have just created, and click on the Listeners tab.

Click on the HTTP:80 and select Edit and then delete the current default action and add a new one that does a redirect to 443.
Testing

You should now be able to access your Jitsi instance from the domain name you are using, and connect to it from your browser.

# Troubleshooting the installation

If you run into issues, then open up the security group for the ECS cluster and allow SSH access from your specific IP address. This will then allow you to use the SSH key to log into the host running the containers, and then use the following commands to help troubleshoot:

```bash
$ docker ps - give you a list of the running containers with container IDs
$ docker exec -it {container id} bash - allow you to get a root user terminal into the container
$ docker logs {container id} - allows you to grab stdOut logs
```

Remember these are container optimized images, so you will not have any of the tools you are used to. In order to install these to help troubleshooting, you will need to run:

```bash
$ apt-dpkg-wrap apt-get update && apt-get install {package}
```

Useful packages to know are vim for editing, dnsutils, and iputils-ping for network testing.

You can use the ecs-cli command-line tool to monitor, stop, and start your clusters. Run the ecs-cli command without parameters or consult the online documentation for more help.

# Changing the size of your cluster

If you want to change the size of your cluster, you have a couple of options:

1. Use the ecs-cli scale --capability-iam --size x, where x is the number of instances you want to scale your cluster to; you can scale up or down.
2. Or you can also do this via AWS CloudFormation. Locate the stack that was used to create your cluster—it should be called something like amazon-ecs-cli-setup-{clustername}—and then use the Update and follow through the instructions to change the cluster configuration.

You might need to do this if you want to have more CPU/memory for your running Jitsi instances.

# Deleting/uninstalling

Once you do not need these capabilities, you should make sure that you remove the Amazon ECS tasks and cluster. You can use the CloudFormation script to automate the deletion of this via the ecs-cli command-line tool:

```bash
$ ecs-cli service down
```

# Advanced installation

As per the Amazon EC2 instance, refer to the project installation documents on GitHub to get more details on configuring Jitsi behind a NAT instance. There will probably be more complexities getting some of those working on Amazon ECS, so get in touch via the comments below and let us know how you get on.
