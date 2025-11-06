#!/bin/bash
# redirect stdout/stderr to a file
#exec &> /save/ec2-user/OWP/laura/schism_cloud_sandbox_log.txt

set -e       # exit immediately on error
set -x       # verbose with command expansion
set -u       # forces exit on undefined variables

export SCRIPT=$1
export EXEC=$2

# Inquire whether or not if a user has attempted to specify
# multiple host nodes to run a basic Python script. If so
# we throw an error exit since Python cannot communicate
# with multiple host nodes without a dask client implementation
# or a MPI based Python application
if [[ "$HOSTS" == *','* ]]; then
    echo "Error: Multiple nodes have been specified for a basic Python script. Basic Python scripts can only run on a single node instance. Exiting..."
    exit 1
fi

# Inquire if Python executable exists, otherwise throw error and exit
if [ ! -x "$EXEC" ]; then
        echo "Error: Python pathway '$SCRIPT' is not an executable. Exiting..."
        exit 1
fi

# Inquire if file exists, otherwise throw error and exit
if [ ! -f "$SCRIPT" ]; then
	echo "Error: File '$SCRIPT' does not exist or is not a regular file. Exiting..."
	exit 1
fi

SECONDS=0

export CLOUDFLOW_DIR=$(pwd)

echo "--- " 
echo "--- SSH Into AWS Worker Node and Running PYTHON Script-----------------"
echo "---"

ssh ec2-user@$HOSTS "cd $CLOUDFLOW_DIR && env && pwd && $EXEC $SCRIPT"


if [ $? -ne 0 ]; then
  echo "ERROR returned from Python executable"
else
  echo "Python script execution has succesfully completed on the cloud!"
  duration=$SECONDS
  echo "Python script execution took $((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
fi


