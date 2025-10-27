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

#__copyright__ = "Copyright © 2025 Tetra Tech, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

if [ $# -lt 6 ] ; then
  echo "Usage: $0 JOBTYPE APP NPROCS PPN HOSTS MODEL_DIR EXEC"
  exit 1
fi

# This was created to launch a job via Python
# The Python scripts create the cluster on-demand
# and submits this job with the list of hosts available.

# Export user defined options within the tasks.basic_run Python function
export JOBTYPE=$1
export APP=$2
export NPROCS=$3
export PPN=$4
export HOSTS=$5
export MODEL_DIR=$6
export EXEC=$7

# Unique extra option required for SCHISM
if [[ "$JOBTYPE" == "schism_experiment" && "APP" == "basic"]]; then
  export NSCRIBES=$8
fi

#Unique extra option required for DFlow FM
if [[ "$JOBTYPE" == "dflowfm_experiment"  && "APP" == "basic"]]; then
  export DFLOW_LIB=$8
fi

#Unique extra option required for ROMS
if [[ "$JOBTYPE" == "roms_experiment" && "APP" == "basic"]]; then
  export IN_FILE=$8
fi

#Unique extra option required for ROMS
if [[ "$JOBTYPE" == "ucla-roms" && "APP" == "basic"]]; then
  export IN_FILE=$8
  export RUNCORES=$9
fi

#Unique extra option required for FVCOM
if [[ "$JOBTYPE" == "fvcom_experiment" && "APP" == "basic"]]; then
  export CASE_FILE=$8
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
 if [[ "$JOBTYPE" == "ucla-roms" ]]; then
    export MPIOPTS="-launcher ssh -hosts $HOSTS -np $RUNCORES"
  # Slice up SCHISM tasks between OpenMP and MPI protocols to 
  # optimize memory allocation for the slave ranks. This method
  # will allow the hpc node instances to work with large SCHISM
  # meshes. For smaller meshes, consider revising $SCHISM_ntasks
  # and $SCHISM_NPROCS to just both be equal to $NPROCS
  elif [[ "$JOBTYPE" == "schism_basic" ]]; then
    export SCHISM_ntasks=70
    export OMP_NUM_THREADS=1
    export SCHISM_NPROCS=$((SCHISM_ntasks*(NPROCS/96)))
    export MPIOPTS="-launcher ssh -hosts $HOSTS -np $SCHISM_NPROCS -ppn $SCHISM_ntasks"
  else
    export MPIOPTS="-launcher ssh -hosts $HOSTS -np $NPROCS -ppn $PPN"
  fi
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
###### it within this basic launcher script after we have      ######
###### predefined all the required environmental variables     ######
###### for you properly within the cloud cluster initilaized   ######

if [[ "$JOBTYPE" == "wrf_hydro_experiment" && "APP" == "basic"]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./wrf_hydro_basic_run.sh $MODEL_DIR $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$JOBTYPE" == "schism_experiment" && "APP" == "basic"]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./schism_basic_run.sh $MODEL_DIR $NSCRIBES $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$JOBTYPE" == "dflowfm_experiment" && "APP" == "basic"]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./dflowfm_basic_run.sh $MODEL_DIR $DFLOW_LIB $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$JOBTYPE" == "adcirc_experiment" && "APP" == "basic"]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./adcirc_basic_run.sh $MODEL_DIR $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$JOBTYPE" == "roms_experiment" && "APP" == "basic"]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./roms_basic_run.sh $MODEL_DIR $IN_FILE $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$JOBTYPE" == "ucla-roms" ]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./ucla-roms_run.sh $MODEL_DIR $IN_FILE $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

elif [[ "$JOBTYPE" == "fvcom_experiment" && "APP" == "basic"]]; then

    # location of model shell launch script
    export JOBDIR=$PWD/workflows

    # TODO:
    cd "$JOBDIR" || exit 1

    RUNSCRIPT="./fvcom_basic_run.sh $MODEL_DIR $CASE_FILE $EXEC"

    # Run it
    $RUNSCRIPT
    result=$?

else
    echo "Model jobtype $JOBTYPE and application $APP not supported"
    exit 1
fi

exit $result


