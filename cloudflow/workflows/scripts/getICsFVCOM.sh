#!/bin/bash
#set -x
#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


. /usr/share/Modules/init/sh
module use -a /usrx/modulefiles
module load produtil
module load gcc

if [ $# -lt 4 ] ; then
  echo "Usage: $0 YYYYMMDD HH ngofs|negofs|etc. COMDIR "
  exit 1
fi

CDATE=$1
cyc=$2
ofs=$3
COMDIR=$4

if [ -d $COMDIR ]; then
 list=`ls -1 $COMDIR | wc -l`
 if [ $list -gt 4 ] ; then
   echo "Looks like ICs already exist. .... skipping"
   echo "Remove the files in $COMDIR to re-download."
   exit 0
 fi
fi

#COMDIR=${COMDIR:-/com/nos/${ofs}.$CDATE}
mkdir -p $COMDIR
cd $COMDIR


nomads=https://nomads.ncep.noaa.gov/pub/data/nccf/com/nosofs/prod/${ofs}.${CDATE}

pfx=nos.$ofs
sfx=${CDATE}.t${cyc}z.nc

flist="
  $pfx.met.forecast.$sfx
  $pfx.obc.$sfx
  $pfx.river.$sfx.tar
  $pfx.hflux.forecast.$sfx
  $pfx.forecast.${CDATE}.t${cyc}z.in
  $pfx.init.nowcast.$sfx
"
#nos.negofs.river.20200312.t03z.nc.tar

for file in $flist
do
  echo "wget $nomads/$file"
  wget -nc -nv $nomads/$file
done

# If negofs or nwgofs, we can either retrieve the obc file from NOMADS as done above
# OR we can copy it from a locally ran ngofs forecast from the same day
#
# Example:
# Rename:
# /com/nos/ngofs.20200225/nos.ngofs.nestnode.nwgofs.forecast.20200225.t03z.nc
# to: 
# /com/nos/nwgofs.20200225/nos.nwgofs.obc.20200225.03.nc


# Fetch the restart/init file
# The restart file is the next cycle's 'init' file

# Get $cdate$cyc +6 hours init file, rename it to $cdate$cyc restart file
NEXT=`$NDATE +6 ${CDATE}${cyc}`
NCDATE=`echo $NEXT | cut -c1-8`
ncyc=`echo $NEXT | cut -c9-10`

nsfx=${NCDATE}.t${ncyc}z.nc

# if current cycle is last for the day, the next cycle will be during the next day
if [ "$cyc" -eq "21" -o "$cyc" -eq "18" ] ; then
  nomads=https://nomads.ncep.noaa.gov/pub/data/nccf/com/nosofs/prod/${ofs}.$NCDATE
fi


ifile=${pfx}.init.nowcast.${nsfx}
rfile=${pfx}.rst.nowcast.${sfx}

wget -nc -nv ${nomads}/$ifile
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Unable to retrieve $ifile from $nomads"
fi

# Rename it
cp -p $ifile $rfile

