#!/bin/bash

INSTANCEID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
IFACE=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs)
SUBNET_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${IFACE}/subnet-id)
VPC_ID=$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${IFACE}/vpc-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')

echo "INSTANCEID: $INSTANCEID"
echo "IFACE: $IFACE"
echo "SUBNET_ID: $SUBNET_ID"
echo "VPC_ID: $VPC_ID"
echo "REGION: $REGION"

# Can manually create an AMI here

# ami_name="IOOS Cloud Sandbox AMI"
# project="IOOS-cloud-sandbox"

# /usr/local/bin/aws --region ${REGION} ec2 create-image --instance-id $INSTANCEID --name "${ami_name}" \
#  --tag-specification "ResourceType=image,Tags=[{Key=\"Name\",Value=\"${ami_name}\"},{Key=\"Project\",Value=\"${project}\"}]"
