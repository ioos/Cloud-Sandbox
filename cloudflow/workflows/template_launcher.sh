#!/bin/env bash

# Script used to launch forecasts.
# BASH is used to bridge between the Python workflow and BASH based run scripts

set -e       # exit immediately on error
set -u       # forces exit on undefined variables
set -a       # makes defined arguments in shell script global

# Set core and stack size
# in cloud cluster environment
# to be unlimited for model access
ulimit -c unlimited
ulimit -s unlimited

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

if [ $# -lt 6 ] ; then
  echo "Usage: $0 OFS NPROCS PPN HOSTS MODEL_DIR EXEC"
  exit 1
fi

# This was created to launch a job via Python
# The Python scripts create the cluster on-demand
# and submits this job with the list of hosts available.

# Export user defined options within the tasks.template_run Python function
export OFS=$1
export NPROCS=$2
export PPN=$3
export HOSTS=$4
export MODEL_DIR=$5
export EXEC=$6

# Unique extra option required for SCHISM
if [[ "$OFS" == "schism" ]]; then
  export NSCRIBES=$7
fi

#Unique extra option required for D-Flow FM
if [[ "$OFS" == "dflowfm" ]]; then
  export DFLOW_LIB=$7
fi

#Unique extra option required for ROMS
if [[ "$OFS" == "roms" ]]; then
  export IN_FILE=$7
fi

#Unique extra option required for FVCOM
if [[ "$OFS" == "fvcom" ]]; then
  export CASE_FILE=$7
fi

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


# MPIOPTS required to ingest for model execution of your given
# script for the cloud cluster that was called by the user
if [ $openmpi -eq 1 ]; then
  export MPIOPTS="-host $HOSTS -np $NPROCS -npernode $PPN -oversubscribe"
elif [ $impi -eq 1 ]; then
  # Since the current Cloud-Sandbox module compatibility with ROMS
  # main branch only allows for the OPENMP parallelization option,
  # we will need to include special MPI options for the model to
  # correctly run OPENMP code structure within the allocated AWS
  # cloud resources specified by the given user
  if [[ "$OFS" == "roms" ]]; then
    export MPIOPTS="-launcher ssh -hosts $HOSTS --bind-to none -np 1"
  else
    export MPIOPTS="-launcher ssh -hosts $HOSTS -np $NPROCS -ppn $PPN"
  fi
  #export I_MPI_OFI_LIBRARY_INTERNAL=1  # Use intel's fabric library
  export I_MPI_OFI_LIBRARY_INTERNAL=0   # Using AWS EFA Fabric on AWS
  export I_MPI_DEBUG=0
else
  echo "ERROR: Unsupported mpirun version ..."
  exit 1
fi


echo "**********************************************************"
echo "Current directory is $PWD"
echo "**********************************************************"


###### This section here is required to be modified for a user ######
###### executing a new model suite to the Cloud-Sandbox, where ######
###### this section essentially just locates a user-defined    ######
###### shell launcher script for your given model and executes ######
###### it within this template launcher script after we have   ######
###### predefined all the required environmental variables     ######
###### for you properly within the cloud cluster initilaized   ######


if [[ "$OFS" == "nwmv3_wrf_hydro" ]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./nwmv3_wrf_hydro_template_run.sh $MODEL_DIR $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$OFS" == "schism" ]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./schism_template_run.sh $MODEL_DIR $NSCRIBES $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$OFS" == "dflowfm" ]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./dflowfm_template_run.sh $MODEL_DIR $DFLOW_LIB $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$OFS" == "adcirc" ]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./adcirc_template_run.sh $MODEL_DIR $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$OFS" == "roms" ]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./roms_template_run.sh $MODEL_DIR $IN_FILE $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$OFS" == "fvcom" ]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./fvcom_template_run.sh $MODEL_DIR $CASE_FILE $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

else
    echo "Model not supported $OFS"
    exit 1
fi

exit $result


