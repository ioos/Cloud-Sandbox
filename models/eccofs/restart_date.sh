#!/usr/bin/env bash

# Compute the new start date to continue a previous run of N days
# 
COMDIR=/com/$USER/nosofs

module load netcdf-c >& /dev/null

pdate=$1
refdate=2011010100

if [ $# -ne 1 ]; then
  echo "Description: Gets the valid restart date from a previous run restart file"
  echo ""
  echo "Usage: $0 <YYYYMMDD>"
  exit 1
fi

lastrun=/com/patrick/nosofs/eccofs.$pdate/eccofs.$pdate.rst.nc
if [ ! -f $lastrun ] ; then
  echo "ERROR: could not find $lastrun"
  exit 2
fi

line=$(ncdump -v ocean_time $lastrun | grep "ocean_time = " | tail -n1 | awk -F= '{print $2}')
seconds=${line##*, }
seconds=${seconds%;} 
# echo "seconds: $seconds"

cd ../../cloudflow/utils
ndate=$(./ndate_secs.py $refdate $seconds)
echo "New start date: $ndate"
