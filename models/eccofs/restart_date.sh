#!/usr/bin/env bash

# Compute the new start date to continue a previous run of N days

# TODO: This could be integrated with the worklow to dynamically 
#       determine the correct CDATE and INIFILE for a run
#       for now, it is a manual step

COMDIR=/com/$USER/nosofs

SCRIPT_DIR=$(
  CDPATH= cd -- "$(dirname -- "$0")" && pwd -P
)
#echo "$SCRIPT_DIR"

module load netcdf-c >& /dev/null

pdate=$1
refdate=2011010100

if [ $# -ne 1 ]; then
  echo "Description: Gets the valid restart date from a previous run restart file"
  echo ""
  echo "Usage: $0 <YYYYMMDD>"
  exit 1
fi

lastrun=$COMDIR/eccofs.$pdate/eccofs.$pdate.rst.nc
if [ ! -f $lastrun ] ; then
  echo "ERROR: could not find $lastrun"
  exit 2
fi

#line=$(ncdump -v ocean_time $lastrun | grep "ocean_time = " | tail -n1 )
#echo $line

line=$(ncdump -v ocean_time $lastrun | grep "ocean_time = " | tail -n1 | awk -F= '{print $2}')
seconds=${line##*, }
seconds=${seconds%;} 

cd $SCRIPT_DIR

cd ../../cloudflow/utils
ndate=$(./ndate_secs.py $refdate $seconds)
echo "New start date: $ndate"
