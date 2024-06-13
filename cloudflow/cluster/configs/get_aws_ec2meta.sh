#!/bin/bash
#set -x

TOKEN=`curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
META="http://169.254.169.254/latest/meta-data"

INSTANCEID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $META/instance-id)
IFACE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $META/network/interfaces/macs)
SUBNET_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $META/network/interfaces/macs/${IFACE}/subnet-id)
VPC_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $META/network/interfaces/macs/${IFACE}/vpc-id)
REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $META/placement/availability-zone | sed 's/[a-z]$//')
MAC=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $META/network/interfaces/macs | head -1)
SGIDS=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" $META/network/interfaces/macs/${MAC}/security-group-ids)

#AMIID=`tail /tmp/setup.log | grep ImageId`

#PLACEMENT_GROUP=`aws ec2 describe-placement-groups | grep GroupId | awk -F\" '{print $4}'`
#PLACEMENT_GROUP=`aws ec2 describe-placement-groups | grep GroupId`

echo "instanceid: $INSTANCEID"
#echo "iface: $IFACE"
echo "region: $REGION"
echo "vpc_id: $VPC_ID"
echo "image_id: $AMIID"
echo "sg_ids: "
echo "$SGIDS"
echo "subnet_id: $SUBNET_ID"
echo "placement_group: $PLACEMENT_GROUP"

#tail /tmp/setup.log | grep ImageId

# Can manually create an AMI here
# ami_name="IOOS Cloud Sandbox AMI"
# project="IOOS-cloud-sandbox"

# /usr/local/bin/aws --region ${REGION} ec2 create-image --instance-id $INSTANCEID --name "${ami_name}" \
#  --tag-specification "ResourceType=image,Tags=[{Key=\"Name\",Value=\"${ami_name}\"},{Key=\"Project\",Value=\"${project}\"}]"
