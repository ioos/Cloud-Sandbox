#!/bin/bash
set -e

# AWS CLI command to launch an EC2 instance
aws \
    --profile lcsb-admin \
    --region us-east-2 \
    ec2 run-instances \
    --image-id ami-0dadf60ed85fe3c7c \
    --instance-type t3.large \
    --subnet-id subnet-0db88d9c9d9a1621c \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=IOOS-Instance}]' \
    --count 1 \
    --associate-public-ip-address \
    --key-name trial \
    --output json

echo "EC2 instance launch initiated"