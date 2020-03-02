#!/bin/sh -x

. /usr/share/Modules/init/sh
module load produtil
module load gcc

if [ $# -ne 2 ] ; then
  echo "Usage: $0 YYYYMMDD HH"
  exit 1
fi

CDATE=$1
cyc=$2

# Need to create a single script that will do any ofs

ICDIR=/noscrub/com/nos/ngofs.$CDATE
mkdir -p $ICDIR
cd $ICDIR

nomads=https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/ngofs.${CDATE}

pfx=nos.ngofs
sfx=${CDATE}.t${cyc}z.nc

flist="
  $pfx.met.forecast.$sfx
  $pfx.obc.$sfx
  $pfx.river.$sfx.tar
  $pfx.hflux.forecast.$sfx
  $pfx.forecast.${CDATE}.t${cyc}z.in
  $pfx.init.nowcast.$sfx
"

#mkdir ngofs.$CDATE
#cd ngofs.$CDATE

for file in $flist
do
  echo "wget $nomads/$file"
  wget -nc $nomads/$file
done

# Fetch the restart/init file

# Get $cdate$cyc +6 hours init file, rename it to $cdate$cyc restart file
NEXT=`$NDATE +6 ${CDATE}${cyc}`
NCDATE=`echo $NEXT | cut -c1-8`
ncyc=`echo $NEXT | cut -c9-10`

nsfx=${NCDATE}.t${ncyc}z.nc

if [ $cyc == 21 ] ; then
  nomads=https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/ngofs.$NCDATE
fi

# nos.ngofs.forecast.20191025.tz.in
ifile=${pfx}.init.nowcast.${nsfx}
rfile=${pfx}.rst.nowcast.${sfx}

wget -nc ${nomads}/$ifile
if [[ $? -ne 0 ]] ; then
  echo "ERROR: Unable to retrieve $file from $nomads"
fi

# Rename it
cp -p $ifile $rfile
