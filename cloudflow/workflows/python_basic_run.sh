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
echo "--- SSH into AWS worker node, checking PYTHON script for syntax errors, and running PYTHON script ---"
echo "---"

# Enable SSH options for strict exit propagation & connection timeouts:
# -o ConnectTimeout=10      : Drops connection if host is unreachable
# -o ServerAliveInterval=15 : Sends keepalives every 15s so stale EC2 connections drop
# -o ServerAliveCountMax=3  : Kills SSH if 3 keepalives fail (45s total)

ssh ConnectTimeout=10 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 $HOSTS bash -s << EOF
  set -e  # Immediately exit remote shell if any command returns non-zero code
  
  cd "$CLOUDFLOW_DIR"
  
  echo "[REMOTE] Environment check:"
  pwd
  
  echo "[REMOTE] Compiling Python script for syntax check..."
  $EXEC -m py_compile "$SCRIPT"
  
  echo "[REMOTE] Running Python script..."
  exec $EXEC -u "$SCRIPT"
EOF

# Capture the exact exit code from SSH
PYTHON_EXIT_CODE=$?

if [ $PYTHON_EXIT_CODE -ne 0 ]; then
  echo "ERROR: Remote Python script failed with exit code $PYTHON_EXIT_CODE" >&2
  exit $PYTHON_EXIT_CODE
else
  echo "Python script execution has successfully completed on the cloud!"
  duration=$SECONDS
  echo "Python script execution took $((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
fi
