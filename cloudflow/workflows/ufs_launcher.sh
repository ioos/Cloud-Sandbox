#!/usr/bin/env bash

# https://ufs-coastal-application.readthedocs.io/en/latest/index.html

# This runs the regression test script.

echo "The RT does a compile job and then the forecast job"

# Use this to:
# If you are using a shared "USER" account, make sure to
# set the below path to your own SAVE space 
# or provide it as a command argument

export CURHOME=$PWD
export CSHOME="${PWD%/*/*}"

echo "Cloud-Sandbox/ directory is: $CSHOME"

#module use -a /save/ec2-user/Cloud-Sandbox/models/ufscoastal/modulefiles
#module use -a $CURHOME/modulefiles

export MACHINE_ID=ioossb
export ACCNR=IOOS   # Not used in ioosb but needed by rt.sh

nprocs=$(nproc)

export SAVEDIR=${1:-"/save/$USER"}
export PTMP=${2:-${dprefix}/ptmp/$USER}
export TESTNAME=${3:-coastal_irene_atm2roms}
export SKIPCOMPILE=${4:-"NO"}
export SKIPCOMPILE="YES"
export HOSTS=${5:-localhost}
export NPROCS=${6:-$nprocs}

# PPN conflicts and gets changed by rt.sh system
export CFPPN=${7:-$nprocs}
export CFPPN=24

export DISKNM=/com/ufs-weather-model/RT
#export dprefix=/mnt/efs/fs1
#export PTMP=${dprefix}/ptmp/$USER
export STMP=$PTMP

cd $SAVEDIR/ufs-weather-model/tests || exit 1
RTCONF_FILE=rt_ioossb.conf

mkdir -p $DISKNM

# Download files - DONE
# Irene ROMS input files supposedly here:
# https://github.com/myroms/roms_test.git
# https://github.com/myroms/roms_test/tree/main/IRENE

# Needed for ptmp and stmp folders in rt.sh
#    dprefix=${dprefix:-"/mnt/efs/fs1"}
#    DISKNM=${DISKNM:-"/com/ufs-weather-model/RT"}
#    STMP=${STMP:-"${dprefix}/stmp"}
#    PTMP=${PTMP:-"${dprefix}/ptmp"}

#sudo mkdir -p $dprefix/stmp
#sudo chown $USER:$USER $dprefix/stmp
#chmod 777 $dprefix/stmp
#mkdir -p $dprefix/ptmp


# /com/ufs-weather-model/RT/NEMSfv3gfs/input-data-20250507
#     module use /save/ec2-user/Cloud-Sandbox/models/ufscoastal/modulefiles
#     module load ufs_ioossb.intel.tcl

# Also downloaded this with help from Jason
#INPUTDATA_ROOT=${INPUTDATA_ROOT:-${DISKNM}/NEMSfv3gfs/input-data-20250507}
#INPUTDATA_ROOT_WW3=${INPUTDATA_ROOT}/WW3_input_data_20250225
#INPUTDATA_LM4=${INPUTDATA_LM4:-${INPUTDATA_ROOT}/LM4_input_data}

# Can not use rocoto although using "none" as a scheduler was an old idea that was never implemented fully
# https://github.com/christopherwharrop/rocoto/issues/18
# Fake slurm implemented in SRWApp but not here
# https://github.com/ufs-community/ufs-srweather-app/pull/508

# rt.sh will create a compile job_card
# rt.sh will create a run test job_card
# /save/ec2-user/ufs-weather-model/tests/fv3_conf
# -rw-rw-r--.  1 ec2-user ec2-user  1712 Apr  2 21:40 fv3_cloudflow.IN_ioossb
# -rw-rw-r--.  1 ec2-user ec2-user   540 Apr  3 20:45 compile_cloudflow.IN_ioossb

# PT: TODO: add a -x skip_compile option like on tests/opnReq script
if [[ ${SKIPCOMPILE} = 'YES' ]]; then
  ./rt.sh -x -a $ACCNR -l $RTCONF_FILE -c -k -n "$TESTNAME intel"
  rc=$?
else
  ./rt.sh -a $ACCNR -l $RTCONF_FILE -c -k -n "$TESTNAME intel"
  rc=$?
fi

# ./rt.sh -l rt_coastal.conf -k -n "coastal_irene_atm2roms intel"
#./rt.sh -a $ACCNR -l $RTCONF_FILE -c -k -n "coastal_irene_atm2roms intel"
# ./rt.sh -r -v -a $ACCNR -l $RTCONF_FILE -c -k -n "coastal_irene_atm2roms intel"
#./rt.sh -v -a $ACCNR -c -k -l $RTCONF_FILE
# ./rt.sh -a -v $ACCNR -c -b $RTCONF_FILE
# ./rt.sh -a -v $ACCNR -c -b $RTCONF_FILE -l $RTCONF_FILE

exit $rc

# Usage: ./rt.sh -a <account> | -b <file> | -c | -d | -e | -h | -k | -l <file> | -m | -n <name> | -o | -r | -v | -w
#
#  -a  <account> to use on for HPC queue
#  -b  create new baselines only for tests listed in <file>
#  -c  create new baseline results
#  -d  delete run directories that are not used by other tests
#  -e  use ecFlow workflow manager
#  -h  display this help
#  -k  keep run directory after rt.sh is completed
#  -l  runs test specified in <file>
#  -m  compare against new baseline results
#  -n  run single test <name>
#  -o  compile only, skip tests
#  -r  use Rocoto workflow manager
#  -v  verbose output
#  -w  for weekly_test, skip comparing baseline results
#
# Since the UFS Coastal specific input files are not part of the UFS Weather Model input files, the location of the RT directory (defined by DISKNM variable) in rt.sh needs to be modified to run UFS Coastal specific RTs. To do that user needs to edit platform (i.e. Orion, Hercules) specific section of rt.sh and set DISKNM variable. For both Orion and Hercules platforms, /work2/noaa/nems/tufuk/RT directory is used to set DISKNM variable.
# 
# To run rt.sh using a custom configuration file and the Rocoto workflow manager:
# 
# ./rt.sh -r -l rt_coastal.conf
# To run a single test from custom configuration file:
# 
# Running with Intel compiler:
# ./rt.sh -l rt_coastal.conf -k -n "coastal_irene_atm2roms intel"
# 
# Running with GNU compiler:
# ./rt.sh -l rt_coastal.conf -k -n "coastal_irene_atm2roms gnu"
# Note
# 
# -k argument is used to keep the run directory for further reference.
# 
