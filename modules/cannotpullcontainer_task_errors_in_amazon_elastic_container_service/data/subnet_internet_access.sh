

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