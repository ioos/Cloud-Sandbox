#!/usr/bin/env bash
# set -e

INPUTDIR=/com/eccofs/input

# Using tar puts too much load on EFS
# Using s3 sync instead

# VPC access point: s3://arn:aws:s3:us-east-2:579273261343:accesspoint/ioos-sandbox-use2-accesspoint

BUCKET=s3://ioos-transfers/eccofs/input
# BUCKET=s3://ioos-sandbox-use2/public/eccofs/input

if [ ! -d $INPUTDIR ]; then
    mkdir -p $INPUTDIR
    result=$?
    if [ $result -ne 0 ]; then
        echo "Unable to create $INPUTDIR, might need sudo permissions"
    fi
fi

cd $INPUTDIR || exit 1

echo "Copying eccofs inputs from s3 ..."

aws s3 sync $BUCKET .

echo "...completed"

