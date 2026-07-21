#!/bin/bash
# Script used to launch forecasts.
# BASH is used in order to bridge between the Python interface and NCO's BASH based run scripts
# set -x

set -ae

ulimit -c unlimited
ulimit -s unlimited

#__copyright__ = "Copyright © 2026 Tetra Tech, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

if [ $# -lt 8 ] ; then
  echo "Usage: $0 YYYYMMDD HH COMOUT SAVEDIR NPROCS PPN HOSTS <cbofs|ngofs2|liveocean|secofs etc.>"
  exit 1
fi

# Note: module load might reset I_MPI options to their default values
#       set these values AFTER loading modules
#       older intel MPI fabric does not work on hpc8a

export I_MPI_OFI_LIBRARY_INTERNAL=0   # 0: use aws efa fabric 1: use intel efa fabric

export FI_PROVIDER=efa
export I_MPI_FABRICS=ofi
export I_MPI_OFI_PROVIDER=efa
export I_MPI_DEBUG=1

export LD_LIBRARY_PATH="/opt/amazon/efa/lib64:$LD_LIBRARY_PATH"
export FI_PROVIDER_PATH=/opt/amazon/efa/lib64/libfabric

# module load libfabric-aws

#export I_MPI_DEBUG=1      # Will output the details of the fabric being used
#export I_MPI_DEBUG=4      # Will output task mapping

# This was created to launch a job via Python
# The Python scripts create the cluster on-demand
# and submits this job with the list of hosts available.

set -x
export CDATE=$1
export HH=$2
export COMOUT=$3     # job.OUTDIR
export SAVEDIR=$4
export PTMP=$5
export NPROCS=$6
export PPN=$7
export HOSTS=$8
export APP=$9
export EXEC=${10}
export XTRA_ARGS=${11}   # extra args needed for schism/secofs, and eccofs
set +x

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
if [[ $APP == "adnoc" ]]; then
  openmpi=1
  impi=0
elif [[ $APP == "nyh-hindcast" ]]; then
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

shopt -s extglob
nosofs_fvcom='leofs|lmhofs|loofs|lsofs|ngofs2|sscofs|sfbofs'
nosofs_roms='cbofs|ciofs|dbofs|gomofs|tbofs|wcofs|eccofs'


# Can put domain specific options here
case $APP in

  @($nosofs_roms) | @($nosofs_fvcom))
    export OFS=$APP
    export HOMEnos=$SAVEDIR
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh
    export cyc=$HH
    export JOBARGS="$CDATE $HH"
    cd "$JOBDIR" || exit 1
    $JOBSCRIPT $JOBARGS
    result=$?
    ;;


  liveocean)
    export OFS=$APP
    export HOMEnos=$SAVEDIR/LiveOcean
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh
    export JOBARGS="$CDATE $COMOUT"
    cd "$JOBDIR" || exit 1

    echo "About to run $JOBSCRIPT"
    $JOBSCRIPT $JOBARGS
    result=$?
    ;;


  wrfroms)
    export OFS=$APP
    export HOMEnos=$SAVEDIR/WRF-ROMS-Coupled
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh 
    cd "$JOBDIR" || exit 1
    $JOBSCRIPT
    result=$?
    ;;


  ##############################################################################

  eccofs-da)

    #export CDATE=$1
    #export HH=$2
    #export COMOUT=$3     # job.OUTDIR
    #export SAVEDIR=$4
    #export PTMP=$5
    #export NPROCS=$6
    #export PPN=$7
    #export HOSTS=$8
    #export APP=$9
    #EXEC=${10}
    #XTRA=${11}

    set -x
    echo "PT DEBUG"
    export NtileI=${12}
    export NtileJ=${13}
    echo "PT DEBUG"
    set +x

    #export MPIOPTS=${MPIOPTS:-"-np $NPP -ppn $PPN "}

    export OFS=$APP
    export HOMEnos=$SAVEDIR
    export JOBDIR=$HOMEnos

    cd "$JOBDIR" || exit 1

    # A lot of hardcoded stuff in this script, will need to re-work things to generalize it
    # Create a job/template with it and sed/replace in job.init with nPETsX and nPETxY (NTILEI NTILEJ) etc.
    # A bit of a drift from operational versions, can work it out later
    export JOBSCRIPT=$JOBDIR/submit_mixres_rbl4dvar.sh

    module use -a $JOBDIR/modulefiles
    MODULEFILE=intel_x86_64
    module load $MODULEFILE

    export I_MPI_OFI_LIBRARY_INTERNAL=0   # 0: use aws efa fabric 1: use intel efa fabric

    export FI_PROVIDER=efa
    export I_MPI_FABRICS=ofi
    export I_MPI_OFI_PROVIDER=efa
    export I_MPI_DEBUG=1

    #export NPROCS=64
    #export PPN=64

    #export NPROCS=384
    #export PPN=192

    export MPIOPTS="-launcher ssh -hosts $HOSTS -np $NPROCS -ppn $PPN"  

    export LD_LIBRARY_PATH="/opt/amazon/efa/lib64:$LD_LIBRARY_PATH"
    export FI_PROVIDER_PATH=/opt/amazon/efa/lib64/libfabric 

    #$JOBSCRIPT $JOBARGS

    $JOBSCRIPT
    result=$?
    echo "PT DEBUG: I am here $PWD"
    ;;



  ##############################################################################

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

    export I_MPI_OFI_LIBRARY_INTERNAL=0   # 0: use aws efa fabric 1: use intel efa fabric

    export FI_PROVIDER=efa
    export I_MPI_FABRICS=ofi
    export I_MPI_OFI_PROVIDER=efa
    export I_MPI_DEBUG=1

    export LD_LIBRARY_PATH="/opt/amazon/efa/lib64:$LD_LIBRARY_PATH"
    export FI_PROVIDER_PATH=/opt/amazon/efa/lib64/libfabric

    #echo "Patrick testing oversubscribed nodes"
    #export MPIOPTS="-launcher ssh -hosts $HOSTS -np 768 -ppn 64"
    #echo "MPIOPTS=$MPIOPTS"
    #export OMP_NUM_THREADS=1
    #export I_MPI_PIN_DOMAIN=omp

    NSCRIBES=$XTRA_ARGS
    echo "Calling: mpirun $MPIOPTS $EXEC $NSCRIBES"
    starttime=`date +%R`
    echo "STARTING RUN AT $starttime"
    mpirun $MPIOPTS $EXEC $NSCRIBES
    result=$?
    endtime=`date +%R`

    echo "RUN FINISHED AT $endtime"

    # Combine hotstart files if they exist
    # TODO: this needs to run as a separate script post-process job
    # example: what if hotstarts are written every 720 timesteps and not just at the end of the run?
    #if ls -1 outputs/hotstart_0*; then
    #    cd outputs
    #    $SAVEDIR/bin/combine_hotstart7 -i 720
    #fi
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
    echo "Calling: mpirun $MPIOPTS $EXEC --casename=$APP --LOGFILE=$APP.out"
    starttime=`date +%R`

    echo "STARTING RUN AT $starttime"
    mpirun $MPIOPTS $EXEC --casename=$APP --LOGFILE=$APP.out
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
    echo "Model not supported $APP"
    exit 1
    ;;
esac

exit $result
