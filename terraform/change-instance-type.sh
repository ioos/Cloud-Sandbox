#!/bin/bash

if [ $# -ne 2 ];
then
  echo "Usage $0 instance-id instance-type"
  exit 1
fi

INSTANCEID=$1
NEWTYPE=$2

echo "aws --region us-east-2 ec2 modify-instance-attribute --instance-id $INSTANCEID --instance-type $NEWTYPE"

aws --region us-east-2 ec2 modify-instance-attribute --instance-id $INSTANCEID --instance-type $NEWTYPE

