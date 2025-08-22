#!/usr/bin/env bash
set -e

# Available from s3://ioos-sandbox-use2/public/
# Originally from vims http fileserver RUN08j_JZ
# https://ccrm.vims.edu/yinglong/NOAA/COOPS/RUN08j_JZ/

# You must set this as needed for proper folders for your user if different from login user name/path
SBUSER=$USER

DATAFILE=secofs.20171201.inputs.tgz

if [ ! -d /com/$SBUSER/secofs ]; then
    mkdir -p /com/$SBUSER/secofs
fi

cd /com/$SBUSER/secofs || exit 1

aws s3 cp s3://ioos-sandbox-use2/public/secofs/$DATAFILE .
tar -xvf $DATAFILE

# Extracts to ./20171201

# Everything should now be in the 20171201 folder, ready to run the workflow

echo "Testcase data for 20171201 should now be in /com/$SBUSER/secofs/20171201"
echo "Note: from VIMS RUN08j_JZ"
rm $DATAFILE
