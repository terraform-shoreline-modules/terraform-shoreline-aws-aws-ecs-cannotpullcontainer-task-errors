

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