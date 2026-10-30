#!/bin/bash
# redirect stdout/stderr to a file
#exec &> /save/ec2-user/OWP/laura/schism_cloud_sandbox_log.txt

set -e       # exit immediately on error
set -x       # verbose with command expansion
set -u       # forces exit on undefined variables

export SCRIPT=$1
export EXEC=$2

SECONDS=0

# Load the modules that were used to linked mpi4py
# Message Passing Interface implementation within 
# your Python environment as well as the respective
# libraries linked to the MPI executables
module purge

module load intel-oneapi-compilers/2024.2.1-none-none-r2buaru
module load esmf/8.9.1-intel-oneapi-compilers-2024.2.1-xxuz5xf

# Force Hydra to send a SIGKILL (9) instead of a SIGTERM (15) to all ranks
export I_MPI_JOB_ABORT_SIGNAL=9

# Ensure the job terminates immediately if any process exits with a non-zero status
export I_MPI_JOB_TIMEOUT_SIGNAL=9

# System Paths: Point dynamic linker and Libfabric to AWS EFA libraries
export LD_LIBRARY_PATH="/opt/amazon/efa/lib64:$LD_LIBRARY_PATH"
export FI_PROVIDER_PATH="/opt/amazon/efa/lib64/libfabric"

# Fabric Control: Force Intel MPI to use AWS system Libfabric over EFA
export I_MPI_OFI_LIBRARY_INTERNAL=0
export FI_PROVIDER="efa"
export I_MPI_FABRICS="ofi"
export I_MPI_OFI_PROVIDER="efa"

# Instructs Intel MPI to continuously check socket connection health
export I_MPI_HEARTBEAT=1
export I_MPI_EXTRA_TIMEOUT=60

echo "--- " 
echo "--- Checking PYTHON MPI script for syntax errors and running PYTHON MPI script ---"
echo "---"

# Check Python script syntax first
$EXEC -m py_compile "$SCRIPT"
if [ $? -ne 0 ]; then
  echo "ERROR: Syntax error detected in $SCRIPT. Aborting MPI launch." >&2
  exit 1
fi

# Run mpirun with mpi4py abort handler
mpirun $MPIOPTS $EXEC -u -m mpi4py "$SCRIPT"
MPI_EXIT_CODE=$?

if [ $MPI_EXIT_CODE -ne 0 ]; then
  echo "ERROR returned from Python mpirun (Exit Code: $MPI_EXIT_CODE)" >&2
  exit $MPI_EXIT_CODE
else
  echo "Python MPI script execution has successfully completed on the cloud!"
  duration=$SECONDS
  echo "Python script execution took $((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
fi
