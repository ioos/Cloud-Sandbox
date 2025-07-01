#!/usr/bin/env/bash
set -e

# Available on s3://ioos-transfers/
# Also available from s3://ioos-sandbox-use2/public/eccofs/com.eccofs.input.tar
# VPC access point: s3://arn:aws:s3:us-east-2:579273261343:accesspoint/ioos-sandbox-use2-accesspoint
#     (only available within sandbox VPC)

if [ -d /com/eccofs ]; then
    sudo mkdir -p /com/eccofs
    sudo chown ec2-user:ec2-user /com/eccofs
fi

cd /com/eccofs || exit 1

aws s3 cp s3://ioos-transfers/eccofs/com.eccofs.input.tar .
tar -xvf com.eccofs.input.tar

rm com.eccofs.input.tar
