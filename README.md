
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# CannotPullContainer task errors in Amazon Elastic Container Service
---

This incident type occurs when a user attempts to create a task in Amazon Elastic Container Service but receives an error message indicating that the container image specified cannot be retrieved. There are several potential troubleshooting areas, including connection timeout, context cancellation, image not found, Docker Hub rate limiting, and pull access denial. To resolve these issues, users may need to configure their VPC, verify their repository URI and image name, set up proper access using the task execution IAM role, or authenticate their Docker client with Amazon ECR.

### Parameters
```shell
export TASK_DEFINITION_ARN="PLACEHOLDER"

export REPOSITORY_NAME="PLACEHOLDER"

export TASK_EXECUTION_ROLE="PLACEHOLDER"

export TASK_ID="PLACEHOLDER"

export VPC_ID="PLACEHOLDER"

export SUBNET_ID="PLACEHOLDER"

export CLUSTER="PLACEHOLDER"

export ECR_REPOSITORY_URI="PLACEHOLDER"
```

## Debug

### Check if the task definition specifies an existing container image
```shell
aws ecs describe-task-definition --task-definition ${TASK_DEFINITION_ARN}
```

### Verify the repository URI and the image name
```shell
aws ecr describe-images --repository-name ${REPOSITORY_NAME}
```

### Verify that the task execution IAM role has the proper access
```shell
aws iam get-role --role-name ${TASK_EXECUTION_ROLE}
```

### Check the subnet ID of the task
```shell
aws ecs describe-tasks --tasks ${TASK_ID}
```

### Check the VPC configuration
```shell
aws ec2 describe-vpcs --vpc-ids ${VPC_ID}
```

### Check the NAT gateway configuration
```shell
aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=${VPC_ID}"
```

### The task is launched in a private subnet without a NAT gateway configured to route requests to the internet.
```shell


#!/bin/bash



# Set variables

TASK_ID=${TASK_ID}

SUBNET_ID=${SUBNET_ID}

CLUSTER=${CLUSTER}



# Get the VPC ID associated with the subnet

VPC_ID=$(aws ec2 describe-subnets --subnet-ids $SUBNET_ID --query 'Subnets[0].VpcId' --output text)



# Fetch the route table associated with the subnet

ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$SUBNET_ID --query 'RouteTables[0].RouteTableId' --output text)



# If the subnet isn't directly associated with a route table, get the main route table for the VPC

if [ "$ROUTE_TABLE_ID" == "None" ]; then

    ROUTE_TABLE_ID=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC_ID Name=association.main,Values=true --query 'RouteTables[0].RouteTableId' --output text)

fi



# Check if the subnet has an internet gateway

IGW=$(aws ec2 describe-route-tables --route-table-id $ROUTE_TABLE_ID --query 'RouteTables[0].Routes[?GatewayId!=`local`].GatewayId' --output text)



# Check if the subnet has a NAT gateway or NAT instance

NAT=$(aws ec2 describe-route-tables --route-table-id $ROUTE_TABLE_ID --query 'RouteTables[0].Routes[?NatGatewayId!=null || InstanceId!=null]' --output text)



if [[ "$IGW" == igw-* ]]; then

    echo "The subnet $SUBNET_ID is a public subnet."

    echo "The subnet can access the internet via the Internet Gateway: $IGW"

elif [[ ! -z "$NAT" ]]; then

    echo "The subnet $SUBNET_ID is a private subnet."

    echo "However, it can access the internet via NAT."

else

    echo "The subnet $SUBNET_ID is a private subnet and doesn't have direct internet access."

fi


```

## Repair

### Specify ENABLED for Auto-assign public IP when launching the task for tasks in public subnets, and specify DISABLED for Auto-assign public IP when launching the task for tasks in private subnets, and configure a NAT gateway in your VPC to route requests to the internet.
```shell


#!/bin/bash



# Set variables

TASK_ID=${TASK_ID}

TASK_SUBNET=${SUBNET_ID}

VPC_ID=${VPC_ID}



# Determine if task is in public or private subnet

SUBNET_TYPE=$(aws ecs describe-tasks --tasks $TASK_ID | jq -r '.tasks[].attachments[].details[] | select(.name == "subnetId") | .value' | cut -d- -f5)



# Apply appropriate task launch settings based on subnet type

if [ "$SUBNET_TYPE" == "public" ]; then

  aws ecs run-task --task-definition $TASK_ID --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$TASK_SUBNET],assignPublicIp=ENABLED}"

else

  NAT_GATEWAY=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" | jq -r '.NatGateways[0].NatGatewayId')

  aws ecs run-task --task-definition $TASK_ID --launch-type FARGATE --network-configuration "awsvpcConfiguration={subnets=[$TASK_SUBNET],securityGroups=[$TASK_SECURITY_GROUP],assignPublicIp=DISABLED,natGatewayId=$NAT_GATEWAY}"

fi


```

### change the latest image for task definition
```shell


#!/bin/bash

# Set variables

TASK_DEFINITION_ARN=${TASK_DEFINITION_ARN}

REPOSITORY_URI=${ECR_REPOSITORY_URI}





TASK_DEFINITION_NAME=$(echo $TASK_DEFINITION_ARN | awk -F'/' '{print $2}' | awk -F':' '{print $1}')

CONTAINER_NAME=$(aws ecs describe-task-definition --task-definition $TASK_DEFINITION_ARN --query "taskDefinition.containerDefinitions[].name" --output text)

REPOSITORY_NAME=$(echo $REPOSITORY_URI | awk -F '/' '{print $NF}')

IMAGE_NAME=$(aws ecr describe-images --repository-name $REPOSITORY_NAME | jq '.imageDetails | max_by(.imagePushedAt) | .imageTags[0]')



# Update task definition with new image

echo "Updating task definition $TASK_DEFINITION with new image $REPOSITORY_URI:$IMAGE_NAME"

aws ecs register-task-definition --family $TASK_DEFINITION \

  --container-definitions "$(aws ecs describe-task-definition --task-definition $TASK_DEFINITION_ARN \

  | jq --arg containerName $CONTAINER_NAME --arg newImage $REPOSITORY_URI:$IMAGE_NAME \

  '.taskDefinition.containerDefinitions |= map(if .name == $containerName then .image = $newImage else . end)')"



# Check for errors

if [ $? -eq 0 ]; then

  echo "Task definition $TASK_DEFINITION updated successfully with new image $REPOSITORY_URI:$IMAGE_NAME"

else

  echo "Error updating task definition $TASK_DEFINITION with new image $REPOSITORY_URI:$IMAGE_NAME"

fi


```