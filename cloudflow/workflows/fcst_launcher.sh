#!/bin/bash
# Script used to launch forecasts.
# BASH is used in order to bridge between the Python interface and NCO's BASH based run scripts

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
export I_MPI_FABRICS=ofi
export I_MPI_OFI_PROVIDER=efa

# module load libfabric-aws

# LiveOcean
#export I_MPI_OFI_LIBRARY_INTERNAL=1  # Use intel's fabric library
#export I_MPI_OFI_LIBRARY_INTERNAL=1
#export I_MPI_OFI_PROVIDER=efa
#export I_MPI_FABRICS=ofi
#export I_MPI_DEBUG=1      # Will output the details of the fabric being used
#export FI_PROVIDER=efa

# This was created to launch a job via Python
# The Python scripts create the cluster on-demand
# and submits this job with the list of hosts available.


export CDATE=$1
export HH=$2
export COMOUT=$3     # job.OUTDIR
export SAVEDIR=$4
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
    export HOMEnos=$SAVEDIR/LiveOcean
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh
    export JOBARGS="$CDATE $COMOUT"
    cd "$JOBDIR" || exit 1

    echo "About to run $JOBSCRIPT $JOBDIR"
    $JOBSCRIPT $JOBARGS
    result=$?
    ;;
  cbofs | ciofs | dbofs | gomofs | tbofs | leofs | lmhofs | ngofs2 | sfbofs )
    export HOMEnos=$SAVEDIR
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh
    export cyc=$HH
    export JOBARGS="$CDATE $HH"
    cd "$JOBDIR" || exit 1
    $JOBSCRIPT $JOBARGS
    result=$?
    ;;


  wrfroms)
    export HOMEnos=$SAVEDIR/WRF-ROMS-Coupled
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh 
    cd "$JOBDIR" || exit 1
    $JOBSCRIPT
    result=$?
    ;;


  secofs)
    # TODO: use an envvar or something to indicate /ptmp use, think about the many different ways to do this

    mkdir -p $COMOUT
    cd "$COMOUT" || exit 1
    # If using scratch disk use PTMP
    # cd $PTMP || exit 1
    echo "Current dir is: $PWD"
    if [ ! -d outputs ]; then
      mkdir outputs
    fi

    # TODO: need better encapsulation and standardization of module and launch procedure
    # SAVEDIR is job.SAVEDIR
    # e.g. /save/patrick/schism
    module use -a $SAVEDIR
    MODULEFILE=intel_x86_64

    #TODO: make this part of the job config
    module load $MODULEFILE

    export I_MPI_OFI_LIBRARY_INTERNAL=0   # 0: use aws library, 1: use intel library
    export I_MPI_OFI_PROVIDER=efa
    export I_MPI_FABRICS=ofi
    export FI_PROVIDER=efa
    export I_MPI_DEBUG=1      # Will output the details of the fabric being used

    NSCRIBES=$XTRA_ARGS
    echo "Calling: mpirun $MPIOPTS $EXEC $NSCRIBES"
    starttime=`date +%R`
    echo "STARTING RUN AT $starttime"
    mpirun $MPIOPTS $EXEC $NSCRIBES
    result=$?
    endtime=`date +%R`

    echo "RUN FINISHED AT $endtime"

    # Combine hotstart files if they exist
    # TODO: this might need to be run as a separate script post-process job
    # example: what if hotstarts are written every 720 timesteps and not just at the end of the run?
    #if ls -1 outputs/hotstart_0*; then
    #    cd outputs
    #    $SAVEDIR/bin/combine_hotstart7 -i 720
    #fi
    ;;


  eccofs)
    # TODO: use an envvar or something to indicate /ptmp use, think about the many different ways to do this
    cd "$COMOUT" || exit 1
    # If using scratch disk use PTMP
    # cd $PTMP || exit 1
    echo "Current dir is: $PWD"

    # SAVEDIR is job.SAVEDIR
    module use -a $SAVEDIR/modulefiles
    module load intel_x86_64

    export I_MPI_OFI_LIBRARY_INTERNAL=0   # 0: use aws library, 1: use intel library
    export I_MPI_OFI_PROVIDER=efa
    export I_MPI_FABRICS=ofi
    export FI_PROVIDER=efa
    export I_MPI_DEBUG=1      # Will output the details of the fabric being used

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


  necofs)
    
    cd "$COMOUT" || exit 1
    echo "Current dir is: $PWD"
    if [ ! -d output ]; then
      mkdir output
    fi

    module use -a $SAVEDIR/modulefiles
    module load intel_x86_64.impi_2021.12.1

    module list

    export I_MPI_OFI_LIBRARY_INTERNAL=0   # 0: use aws library, 1: use intel library
    export I_MPI_OFI_PROVIDER=efa
    export I_MPI_FABRICS=ofi
    export FI_PROVIDER=efa
    export I_MPI_DEBUG=1      # Will output the details of the fabric being used

    # mpiexec --machinefile $PBS_NODEFILE -np $CPUS ./fvcom --casename=necofs_cold --LOGFILE=tide.out
    echo "Calling: mpirun $MPIOPTS $EXEC --casename=$OFS --LOGFILE=$OFS.out"
    starttime=`date +%R`

    echo "STARTING RUN AT $starttime"
    mpirun $MPIOPTS $EXEC --casename=$OFS --LOGFILE=$OFS.out
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
