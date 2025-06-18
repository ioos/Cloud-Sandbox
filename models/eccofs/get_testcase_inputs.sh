#!/usr/bin/env/bash
set -e

# aws s3 ls s3://ioos-transfers/

if [ -d /com/eccofs ]; then
    sudo mkdir -p /com/eccofs
    sudo chown ec2-user:ec2-user /com/eccofs
fi

cd /com/eccofs || exit 1

aws s3 cp s3://ioos-transfers/eccofs/com.eccofs.input.tar .
tar -xvf com.eccofs.input.tar

echo "manually remove the tar file"

