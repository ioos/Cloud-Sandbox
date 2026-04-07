#!/usr/bin/env bash

# https://ufs-coastal-application.readthedocs.io/en/latest/index.html

# Use this to:

# If you are using a shared "USER" account, make sure to
# set the below path to your own SAVE space 
# or provide it as a command argument

export SAVEDIR=${1:-"/save/$USER"}
export CURHOME=$PWD
export CSHOME="${PWD%/*/*}"

echo "Cloud-Sandbox/ directory is: $CSHOME"

#module use -a /save/ec2-user/Cloud-Sandbox/models/ufscoastal/modulefiles
#module use -a $CURHOME/modulefiles

cd $SAVEDIR/ufs-weather-model/tests || exit 1

# Setting for detect_machine in rt dir.
#sudo hostname ioossb.${HOST}
#echo $HOST
#hostname -f

# Or set explicitly
# If the MACHINE_ID variable is set, skip this script. 
export MACHINE_ID=ioossb

# Download files
# Irene ROMS input files supposedly here:
# https://github.com/myroms/roms_test.git
# https://github.com/myroms/roms_test/tree/main/IRENE

export ACCNR="IOOS"

# Needed for ptmp and stmp folders
export dprefix=/mnt/efs/fs1
DISKNM=/com/ufs-weather-model/RT
mkdir -p $DISKNM
#sudo mkdir -p $dprefix/stmp
#sudo chown $USER:$USER $dprefix/stmp
#chmod 777 $dprefix/stmp
#mkdir -p $dprefix/ptmp

RTCONF_FILE=${CURHOME}/rt_ioossb.conf


# rt.sh support will take more work
# I already have it built, just run a single test

# I already have it built, just run a single test

# Can not use rocoto although using "none" as a scheduler was an old idea that was never implemented fully
# https://github.com/christopherwharrop/rocoto/issues/18
# Fake slurm implemented in SRWApp but not here
# https://github.com/ufs-community/ufs-srweather-app/pull/508
# ./rt.sh -l rt_coastal.conf -k -n "coastal_irene_atm2roms intel"
./rt.sh -a $ACCNR -l $RTCONF_FILE -c -k -n "coastal_irene_atm2roms intel"
# ./rt.sh -r -v -a $ACCNR -l $RTCONF_FILE -c -k -n "coastal_irene_atm2roms intel"
#./rt.sh -v -a $ACCNR -c -k -l $RTCONF_FILE
# ./rt.sh -a -v $ACCNR -c -b $RTCONF_FILE
# ./rt.sh -a -v $ACCNR -c -b $RTCONF_FILE -l $RTCONF_FILE

exit

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
# Note
# 
# -a argument can be used to specify account to job scheduler
