#!/bin/env bash

# source include the functions 
. funcs-setup-instance.sh

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

# export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
export AWS_DEFAULT_REGION=$(curl -sH "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
echo $AWS_DEFAULT_REGION

# curl -H "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/
#instance_id=`curl -s http://169.254.169.254/latest/meta-data/instance-id`
instance_id=`curl -sH "X-aws-ec2-metadata-token: $TOKEN" -v http://169.254.169.254/latest/meta-data/instance-id`

echo "instance_id=$instance_id"

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default

ami_name=${ami_name:='IOOS-Cloud-Sandbox'}

# TODO: pass this in via Terraform init template
project_tag="IOOS-Cloud-Sandbox"

# For some reason these aren't being seen
# Try installing them again in this shell
# python3 -m pip install --user --upgrade botocore==1.23.46
# python3 -m pip install --user --upgrade boto3==1.20.46

# create node image
###################################

image_name="${ami_name}-Node-2"
echo "Node image_name: $image_name"

# Flush the disk cache
sudo sync
image_id=`python3 create_image.py $instance_id "$image_name" "$project_tag"`
echo "Node image_id: $image_id"
