#!/bin/bash
set -x

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


. /usr/share/Modules/init/sh
module use -a /usrx/modulefiles
module load produtil

if [ $# -ne 4 ] ; then
  echo "Usage: $0 YYYYMMDD HH cbofs|(other ROMS model) COMDIR"
  exit 1
fi

CDATE=$1
cyc=$2
ofs=$3
COMDIR=$4

# --no-check-certificate
WGOPTS='-nc -nv --no-check-certificate'
url=https://nomads.ncep.noaa.gov/pub/data/nccf/com/nosofs/prod/${ofs}.$CDATE

#COMDIR=/com/nos/${ofs}.$CDATE
if [ -d $COMDIR ]; then
 list=`ls -1 $COMDIR | wc -l`
 if [ $list -gt 4 ] ; then
   echo "It looks like ICs already exist. Remove the files to force the download... skipping."
   exit 0
 fi
fi
    
mkdir -p $COMDIR
cd $COMDIR


# nos.cbofs.met.forecast.20190906.t00z.nc
# nos.cbofs.obc.20190906.t00z.nc
# nos.cbofs.river.20190906.t00z.nc
# nos.cbofs.roms.tides.20190906.t00z.nc
# nos.cbofs.rst.nowcast.20190906.t00z.nc
# nos.cbofs.forecast.20191001.t00z.in 

pfx=nos.${ofs}
sfx=${CDATE}.t${cyc}z.nc

#https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/gomofs.20200226/nos.gomofs.clim.20200226.t00z.nc


icfiles="
$pfx.met.forecast.$sfx
$pfx.obc.$sfx
$pfx.river.$sfx
$pfx.roms.tides.$sfx
$pfx.forecast.${CDATE}.t${cyc}z.in
"

for file in $icfiles
do
  wget $WGOPTS ${url}/$file
  if [[ $? -ne 0 ]] ; then
    echo "ERROR: Unable to retrieve $file from $url"
    exit -1
  fi
done

# Need to rename the tides file - roms is still using generic name
cp -pf $pfx.roms.tides.$sfx nos.${ofs}.roms.tides.nc 

if [[ "$ofs" == "gomofs" ]]; then
  #nos.gomofs.clim.20200226.t00z.nc
  climfile=$pfx.clim.$sfx
  wget $WGOPTS ${url}/$climfile
  if [[ $? -ne 0 ]] ; then
    echo "ERROR: Unable to retrieve $climfile from $url"
    exit -1
  fi 
fi

# Fetch the restart/init file
# ININAME == nos.cbofs.rst.nowcast.20191001.t00z.nc

# Get $cdate$cyc +6 hours init file, rename it to $cdate$cyc restart file
NEXT=`$NDATE +6 ${CDATE}${cyc}`
NCDATE=`echo $NEXT | cut -c1-8`
ncyc=`echo $NEXT | cut -c9-10`

nsfx=${NCDATE}.t${ncyc}z.nc

if [[ $cyc -eq 18 ]] ; then
  url=https://nomads.ncep.noaa.gov/pub/data/nccf/com/nosofs/prod/${ofs}.$NCDATE 
fi

ifile=${pfx}.init.nowcast.${nsfx}
rfile=${pfx}.rst.nowcast.${sfx}

wget $WGOPTS ${url}/$ifile
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Unable to retrieve $file from \n $url"
  exit -1
fi

# Rename it
cp -p $ifile $rfile




