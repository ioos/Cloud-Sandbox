#!/usr/bin/env bash
# set -e

INPUTDIR=/com/eccofs
DATAFILE=com.eccofs.input.tgz   # 200GB

# Available on s3://ioos-transfers/

# Also available from s3://ioos-sandbox-use2/public/eccofs/com.eccofs.input.tar
# VPC access point: s3://arn:aws:s3:us-east-2:579273261343:accesspoint/ioos-sandbox-use2-accesspoint
#     (only available within sandbox VPC)

if [ ! -d $INPUTDIR ]; then
    mkdir -p $INPUTDIR
    result=$?
    if [ $result -ne 0 ]; then
        echo "Unable to create $INPUTDIR, might need sudo permissions"
    fi
fi

cd $INPUTDIR || exit 1

echo "Input file is 200GB ..."
# TODO - gzip this file
aws s3 cp s3://ioos-transfers/eccofs/$DATAFILE .
tar -xvf $DATAFILE

rm $DATAFILE
