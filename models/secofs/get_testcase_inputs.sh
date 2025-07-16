#!/usr/bin/env bash
set -e

# Available from s3://ioos-sandbox-use2/public/

# Set this as needed for proper folders for your user
SBUSER=$USER

if [ ! -d /com/$SBUSER/secofs ]; then
    mkdir -p /com/$SBUSER/secofs
fi

cd /com/$SBUSER/secofs || exit 1

aws s3 cp s3://ioos-sandbox-use2/public/secofs/secofs.20171201.inputs.tar .
tar -xvf secofs.20171201.inputs.tar

# Everything should now be in the 20171201 folder, ready to run the workflow

rm secofs.20171201.inputs.tar
