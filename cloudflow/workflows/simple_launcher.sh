#!/bin/bash
# Script used to launch forecasts/hindcasts.
# BASH is used in order to bridge between the Python interface and the Linux environment

set -x
set -a

ulimit -c unlimited
ulimit -s unlimited

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

if [ $# -lt 8 ] ; then
  echo "Usage: $0 YYYYMMDD HH COMOUT SAVEDIR NPROCS PPN HOSTS <cbofs|ngofs|liveocean|adnoc|etc.>"
  exit 1
fi

export I_MPI_OFI_LIBRARY_INTERNAL=0   # Using AWS EFA Fabric on AWS
export FI_PROVIDER=efa
export I_MPI_FABRICS=shm:ofi  # default
export I_MPI_OFI_PROVIDER=efa
export I_MPI_DEBUG=1      # Will output the details of the fabric being used

# This was created to launch a job via Python
# The Python scripts create the cluster on-demand
# and submits this job with the list of hosts available.

export JOBTYPE=$1
export HOSTS=$2
export NPROCS=$3
export PPN=$4

export SAVEDIR=$5
export RUNDIR=$6
export INPUTFILE=$7
export EXEC=$8

# TODO: INPUTFILE isn't used, FVCOM expects casename, and the exec expects a nml file that matches the casename
#       or in this case we can use JOBTYPE

# TODO: put the following back in
# mpirun --version | grep Intel
# impi=$?
#
# mpirun --version | grep "Open MPI"
# openmpi=$?

# for openMPI openmpi=1
# for Intel MPI set impi=1
if [[ $JOBTYPE == "adnoc" ]]; then
  openmpi=1
  impi=0
elif [[ $JOBTYPE == "nyh-hindcast" ]]; then
  openmpi=1
  impi=0
else
  openmpi=0
  impi=1
fi

#TODO: Make this section a switch statement instead

# MPIOPTS is used by the fcstrun.sh script for nosofs and wrfroms
if [ $openmpi -eq 1 ]; then
  export MPIOPTS="-host $HOSTS -np $NPROCS -npernode $PPN -oversubscribe"
  #export MPIOPTS="-launch-agent ssh -host $HOSTS -n $NPROCS -npernode $PPN"
elif [ $impi -eq 1 ]; then
  export MPIOPTS="-launcher ssh -hosts $HOSTS -np $NPROCS -ppn $PPN"
  export I_MPI_DEBUG=0
else
  echo "ERROR: Unsupported mpirun version ..."
  exit 1
fi

result=0

# Can put domain specific options here
case $JOBTYPE in
    
  necofs_hot | necofs_cold)
    # TODO: use an envvar or something to indicate /ptmp use, think about the many different ways to do this
    cd "$RUNDIR" || exit 1
    echo "Current dir is: $PWD"

    module use -a $SAVEDIR/modulefiles
    module load intel_x86_64.impi_2021.12.1
    # mpiexec --machinefile $PBS_NODEFILE -np $CPUS ./fvcom --casename=necofs_cold --LOGFILE=tide.out
    echo "Calling: mpirun $MPIOPTS $EXEC --casename=$JOBTYPE --LOGFILE=$JOBTYPE.out"
    starttime=`date +%R`
    
    echo "STARTING RUN AT $starttime"
    #mpirun $MPIOPTS $EXEC --casename=$JOBTYPE --LOGFILE=$JOBTYPE.out
    mpirun $MPIOPTS $EXEC --casename=$JOBTYPE --LOGFILE=$JOBTYPE.out
    result=$?
    echo "wth mpirun result: $result"
    endtime=`date +%R`
    echo "RUN FINISHED AT $endtime"
    ;;
  *)
    echo "$JOBTYPE is not supported by this script $0"
    exit 1
    ;;
esac

exit $result
