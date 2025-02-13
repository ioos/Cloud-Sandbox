#!/bin/env bash

# Script used to launch forecasts.
# BASH is used to bridge between the Python workflow and BASH based run scripts

# set -xa
set -a
ulimit -c unlimited
ulimit -s unlimited

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

if [ $# -ne 7 ] ; then
  echo "Usage: $0 YYYY PROJHOME NPROCS PPN HOSTS CONFIG GRID"
  exit 1
fi

# This was created to launch a job via Python
# The Python scripts create the cluster on-demand
# and submits this job with the list of hosts available.

export YYYY=$1
export PROJHOME=$2
export NPROCS=$3
export PPN=$4
export HOSTS=$5
export CONFIG=$6
export GRID=$7

#OpenMPI
#mpirun --version

#IntelMPI
#mpirun --version

# TODO: put the following back in
# mpirun --version | grep Intel
# impi=$?
#
# mpirun --version | grep "Open MPI"
# openmpi=$?
# for openMPI openmpi=1
# for Intel MPI set impi=1

openmpi=0
impi=1


# MPIOPTS is used by the fcstrun.sh script for nosofs and wrfroms
if [ $openmpi -eq 1 ]; then
  export MPIOPTS="-host $HOSTS -np $NPROCS -npernode $PPN -oversubscribe"
elif [ $impi -eq 1 ]; then
  export MPIOPTS="-launcher ssh -hosts $HOSTS -np $NPROCS -ppn $PPN"
  #export I_MPI_OFI_LIBRARY_INTERNAL=1  # Use intel's fabric library
  export I_MPI_OFI_LIBRARY_INTERNAL=0   # Using AWS EFA Fabric on AWS
  export I_MPI_DEBUG=0
else
  echo "ERROR: Unsupported mpirun version ..."
  exit 1
fi

OFS='adcirc-cora'

echo "**********************************************************"
echo "Current directory is $PWD"
echo "**********************************************************"

#TODO: Make this section a switch statement instead
# Can put domain specific options here
if [[ "$OFS" == "adcirc-cora" ]]; then
    
    export JOBDIR=$PROJHOME

    export RUNDIR=$PROJHOME/ERA5/$GRID/$YYYY

    TRACKSDIR=$PROJHOME/TracksToRun

    cp ./job/templates/submit.cloudflow.template "$JOBDIR/common"
    touch "$TRACKSDIR/${YYYY}.trk"
    
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./bin/run_storms.sh --config $CONFIG --maxrun=1"
    # example ./bin/run_storms.sh -v --config ./configs/ec95d_prior_config.yml --maxrun=1

    # Run it
    $RUNSCRIPT
    result=$?

else
    echo "Model not supported $OFS"
    exit 1
fi

exit $result


