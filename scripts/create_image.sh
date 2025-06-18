#!/bin/env bash
#set -x

ami_name=$1
project_tag=$2

#echo "Requesting TOKEN..."
TOKEN=`curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

#echo "Getting current region..."
export AWS_DEFAULT_REGION=`curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//'`
echo "AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION"

#echo "Getting current instance id..."
instance_id=`curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id`
echo "instance_id: $instance_id"

now=`date -u +\%Y\%m\%d_\%H-\%M`

ami_name=${ami_name:="IOOS-Cloud-Sandbox-${now}"}
echo "ami_name: $ami_name"

# TODO: pass this in via Terraform init template
project_tag=${project_tag:="IOOS-Cloud-Sandbox"}
echo "project_tag: $project_tag"

# create node image
###################################

image_name="${ami_name}-Node"
echo "Node image_name: $image_name"

# Flush the disk cache
sync
python3 create_image.py $instance_id "$image_name" "$project_tag"

