#!/bin/env bash

# Script used to launch forecasts.
# BASH is used in order to bridge between the Python interface and NCO's BASH based run scripts

set -xa
set -a
ulimit -c unlimited
ulimit -s unlimited

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

if [ $# -lt 6 ] ; then
  echo "Usage: $0 YYYY PROJHOME NPROCS PPN HOSTS CONFIG"
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

#OpenMPI
#mpirun --version
#mpirun (Open MPI) 2.1.0

#IntelMPI
#mpirun --version
#Intel(R) MPI Library for Linux* OS, Version 2017 Update 2 Build 20170125 (id: 16752)
#Copyright (C) 2003-2017, Intel Corporation. All rights reserved.

# module -t avail >& avail ; grep mpi avail

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

#TODO: Make this section a switch statement instead

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

# Can put domain specific options here
if [[ "$OFS" == "adcirc-cora" ]]; then
    
    export JOBDIR=$PROJHOME
    export RUNDIR=$PROJHOME/ERA5/ec95d/$YYYY
    TRACKSDIR=$PROJHOME/TracksToRun

    cp ./job/templates/submit.cloudflow.template "$JOBDIR/common"
    touch "$TRACKSDIR/${YYYY}.trk"
    
    cd "$JOBDIR" || exit 1
    RUNSCRIPT="./bin/run_storms.sh --config $CONFIG --maxrun=1"
    # #./bin/run_storms.sh -v --config ./configs/ec95d_prior_config.yml --maxrun=1

    # Run it
    $RUNSCRIPT
    result=$?

else
    echo "Model not supported $OFS"
    exit 1
fi

exit $result


