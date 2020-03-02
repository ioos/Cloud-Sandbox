#!/bin/bash
set -xa
ulimit -c unlimited
ulimit -s unlimited

#__copyright__ = "Copyright © 2020 RPS Group. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

if [ $# -ne 7 ] ; then
  echo "Usage: $0 YYYYMMDD HH COMOUT NPROCS PPN HOSTS <cbofs|ngofs|liveocean|adnoc|etc.>"
  exit 1
fi

#export I_MPI_DEBUG=${I_MPI_DEBUG:-0}
#export I_MPI_FABRICS=${I_MPI_FABRICS:-shm:ofi}
#export I_MPI_FABRICS=efa
#export FI_PROVIDER=efa
#export FI_PROVIDER=tcp

# This was created to launch a job via Python
# The Python scripts create the cluster on-demand 
# and submits this job with the list of hosts available.


export CDATE=$1
export HH=$2
export COMOUT=$3
export NPROCS=$4
export PPN=$5
export HOSTS=$6
export OFS=$7


#OpenMPI
#mpirun --version
#mpirun (Open MPI) 2.1.0

#IntelMPI
#mpirun --version
#Intel(R) MPI Library for Linux* OS, Version 2017 Update 2 Build 20170125 (id: 16752)
#Copyright (C) 2003-2017, Intel Corporation. All rights reserved.

# module -t avail >& avail ; grep mpi avail
# mpirun not in path if module is not loaded
#mpirun --version | grep Intel
#impi=$?
#
#mpirun --version | grep "Open MPI"
#openmpi=$?

if [[ $OFS == "adnoc" ]]; then
  openmpi=1
  impi=0
else
  openmpi=0
  impi=1
fi
  
#TODO: Make this section a switch statement instead


if [ $openmpi -eq 1 ]; then
  export MPIOPTS="-host $HOSTS -np $NPROCS -npernode $PPN -oversubscribe"
  #export MPIOPTS="-launch-agent ssh -host $HOSTS -n $NPROCS -npernode $PPN"
elif [ $impi -eq 1 ]; then
  export MPIOPTS="-launcher ssh -hosts $HOSTS -np $NPROCS -ppn $PPN"
else
  echo "ERROR: Unsupported mpirun version ..."
  exit 1
fi

#export MPIOPTS="-launcher ssh -hosts $HOSTS -np $NPROCS -ppn $PPN"
#export MPIOPTS="-hosts $HOSTS -np $NPROCS -ppn $PPN"

# Can put domain specific options here
case $OFS in
  liveocean)
    export HOMEnos=/save/LiveOcean
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh
    export JOBARGS="$CDATE"
    cd "$JOBDIR" || exit 1
    $JOBSCRIPT "$JOBARGS"
    ;;
  cbofs | dbofs | tbofs | gomofs | ciofs | leofs | sfbofs | ngofs | nwgofs | negofs | lmhofs )
    export HOMEnos=/save/nosofs-NCO
    export JOBDIR=$HOMEnos/jobs
    export JOBSCRIPT=$JOBDIR/fcstrun.sh
    export cyc=$HH
    export JOBARGS="$CDATE $HH"
    cd "$JOBDIR" || exit 1
    $JOBSCRIPT "$JOBARGS"
    ;;
  adnoc)
    EXEC=roms
    export JOBDIR=$COMOUT
    mkdir -p "$JOBDIR"/output
    cd "$JOBDIR" || exit 1
    mpirun "$MPIOPTS" $EXEC ocean.in > ocean.log
    ;;

  *)
    echo "Model not supported $OFS"
    exit 1
    ;;
esac
 
