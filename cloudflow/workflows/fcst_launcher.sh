#!/bin/bash
# Script used to launch forecasts.
# BASH is used in order to bridge between the Python interface and NCO's BASH based run scripts

# WRKDIR=/save/$USER
set -x
set -a

ulimit -c unlimited
ulimit -s unlimited

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


if [ $# -lt 8 ] ; then
  echo "Usage: $0 YYYYMMDD HH COMOUT WRKDIR NPROCS PPN HOSTS <cbofs|ngofs|liveocean|adnoc|etc.>"
  exit 1
fi

export I_MPI_OFI_LIBRARY_INTERNAL=0   # Using AWS EFA Fabric on AWS

# eccofs
export I_MPI_OFI_LIBRARY_INTERNAL=0
export FI_PROVIDER=efa
export I_MPI_FABRICS=shm:ofi  # default
#NOTE: #This option is not applicable to slurm and pdsh bootstrap servers.
# https://www.intel.com/content/www/us/en/docs/mpi-library/developer-reference-linux/2021-15/communication-fabrics-control.html
export I_MPI_OFI_PROVIDER=efa
# module load libfabric-aws

# LiveOcean
#export I_MPI_OFI_LIBRARY_INTERNAL=1
#export I_MPI_OFI_PROVIDER=efa
#export I_MPI_FABRICS=ofi
#export I_MPI_DEBUG=1      # Will output the details of the fabric being used

#export I_MPI_DEBUG=${I_MPI_DEBUG:-0}
#export I_MPI_OFI_LIBRARY_INTERNAL=1  # Use intel's fabric library
#export I_MPI_DEBUG=1
#export I_MPI_FABRICS=efa
#export I_MPI_FABRICS=${I_MPI_FABRICS:-shm:ofi}
#export FI_PROVIDER=efa
#export FI_PROVIDER=tcp

# This was created to launch a job via Python
# The Python scripts create the cluster on-demand
# and submits this job with the list of hosts available.


export CDATE=$1
export HH=$2
export COMOUT=$3    # job.OUTDIR
export WRKDIR=$4    # job.SAVE
export PTMP=$5
export NPROCS=$6
export PPN=$7
export HOSTS=$8
export OFS=$9
export EXEC=${10}
export XTRA_ARGS=${11}   # extra args needed for schism/secofs, and eccofs

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
if [[ $OFS == "adnoc" ]]; then
  openmpi=1
  impi=0
elif [[ $OFS == "nyh-hindcast" ]]; then
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

#export MPIOPTS="-launcher ssh -hosts $HOSTS -np $NPROCS -ppn $PPN"
#export MPIOPTS="-hosts $HOSTS -np $NPROCS -ppn $PPN"
result=0

# Can put domain specific options here
case $OFS in
  liveocean)
    export HOMEnos=$WRKDIR/LiveOcean
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh
    export JOBARGS="$CDATE $COMOUT"
    cd "$JOBDIR" || exit 1

    echo "About to run $JOBSCRIPT $JOBDIR"
    $JOBSCRIPT $JOBARGS
    result=$?
    ;;
  cbofs | ciofs | dbofs | gomofs | tbofs | leofs | lmhofs | negofs | ngofs | nwgofs | sfbofs )
    export HOMEnos=$WRKDIR/nosofs-3.5.0
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh
    export cyc=$HH
    export JOBARGS="$CDATE $HH"
    cd "$JOBDIR" || exit 1
    $JOBSCRIPT $JOBARGS
    result=$?
    ;;
  wrfroms)
    export HOMEnos=$WRKDIR/WRF-ROMS-Coupled
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh 
    cd "$JOBDIR" || exit 1
    $JOBSCRIPT
    result=$?
    ;;
  secofs)
    # TODO: use an envvar or something to indicate /ptmp use, think about the many different ways to do this
    cd "$COMOUT" || exit 1
    # If using scratch disk use PTMP
    # cd $PTMP || exit 1
    echo "Current dir is: $PWD"
    if [[ $OFS == "secofs" ]]; then 
      if [ ! -d outputs ]; then
        mkdir outputs
      else
        rm -f outputs/*
      fi
    fi

    # WRKDIR is job.SAVE 
    # e.g. /save/patrick/schism
    module use -a $WRKDIR
    module load NOS_intel_x86_64
    NSCRIBES = $XTRA_ARGS
    echo "Calling: mpirun $MPIOPTS $EXEC $NSCRIBES"
    starttime=`date +%R`
    #echo "Testing ... sleeping"
    #sleep 300
    echo "STARTING RUN AT $starttime"
    mpirun $MPIOPTS $EXEC $NSCRIBES
    result=$?
    endtime=`date +%R`
    echo "RUN FINISHED AT $endtime"
    ;;
  eccofs)
    # TODO: use an envvar or something to indicate /ptmp use, think about the many different ways to do this
    cd "$COMOUT" || exit 1
    # If using scratch disk use PTMP
    # cd $PTMP || exit 1
    echo "Current dir is: $PWD"

    # WRKDIR is job.SAVE 
    module use -a $WRKDIR/modulefiles
    module load NOS_intel_x86_64
    OCEANIN=$XTRA_ARGS
    echo "Calling: mpirun $MPIOPTS $EXEC $OCEANIN"
    starttime=`date +%R`
    #echo "Testing ... sleeping"
    #sleep 300
    echo "STARTING RUN AT $starttime"
    mpirun $MPIOPTS $EXEC $OCEANIN
    result=$?
    echo "wth mpirun result: $result"
    endtime=`date +%R`
    echo "RUN FINISHED AT $endtime"
    ;;

  adnoc)
    EXEC=${EXEC:-roms}
    export JOBDIR=$COMOUT
    mkdir -p "$JOBDIR"/output
    cd "$JOBDIR" || exit 1
    mpirun $MPIOPTS $EXEC ocean.in > ocean.log
    result=$?
    ;;
  nyh-hindcast)
    EXEC=${EXEC:-roms}
    export JOBDIR=$COMOUT
    mkdir -p $JOBDIR
    cd $JOBDIR || exit 1
    echo "Run command: mpirun $MPIOPTS $EXEC ocean.in > ocean.out 2>&1"
    mpirun $MPIOPTS $EXEC ocean.in > ocean.out 2>&1
  ;;
  adcircofs)
    export JOBDIR=/home/mmonim/Cloud-Sandbox/cloudflow/workflows
    export JOBSCRIPT=$JOBDIR/fcstrun_adcirc_cluster.sh
    cd "$JOBDIR" || exit 1
    $JOBSCRIPT
    result=$?
    ;;
  *)
    echo "Model not supported $OFS"
    exit 1
    ;;
esac

exit $result
