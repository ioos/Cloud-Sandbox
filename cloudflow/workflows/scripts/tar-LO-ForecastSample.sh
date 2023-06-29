#!/bin/bash
set -x
#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


COMDIR=/noscrub/com/liveocean/output
cdate=20191106

#f2019.11.06

# This is awesome syntax - never knew of this substring functionality
YYYY=${cdate:0:4}
MM=${cdate:4:2}
DD=${cdate:6:2}

#echo "YYYY is $YYYY"
#echo "MM is $MM"
#echo "DD is $DD"

#ocean_his_0001.nc
#ocean_his_0006.nc
#ocean_his_0012.nc
#ocean_his_0018.nc
#ocean_his_0024.nc
#ocean_his_0025.nc
#ocean_his_0048.nc

hhlist='0001 0006 0012 0018 0024 0048'

cd $COMDIR

fdir=f${YYYY}.${MM}.${DD}

list=${fdir}.lst
> $list

for hh in $hhlist
do
  echo $fdir/ocean_his_${hh}.nc >> $list
done

tar -czvf aws.${fdir}.tgz -T $list

