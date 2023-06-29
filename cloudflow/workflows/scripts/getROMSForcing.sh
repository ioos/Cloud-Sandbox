#!/bin/sh
set -x
# This receives the forcing data required to run CBOFS prep step
# It needs to be modified to support any ROMS based model

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


. /usr/share/Modules/init/sh
module load produtil
module load gcc

OFS=cbofs
NOMADS=https://nomads.ncep.noaa.gov/pub/data/nccf
#cd $COMOUT
COMROT=/com/forcing
NOWCASTONLY=YES

# Get current cycle forcing data
PDY=20210217
PDATE=`$NDATE -24 ${PDY}00 | cut -c1-8`
HH=00

# Get previous cycle for init time, need some overlap
#PDY=20190905

#ETSS - storm surge
product=etss
COM=$COMROT/$product/$product.$PDY
mkdir -p $COM
cd $COM

# 00z to 18z available
FHList='00 06 12 18'
for FH in $FHList
do
  # etss.t18z.stormsurge.con2p5km.grib2  
  wget -nc $NOMADS/com/$product/prod/${product}.$PDY/$product.t${FH}z.stormsurge.con2p5km.grib2
  # Need etss for Alaska for CIOFS
  wget -nc $NOMADS/com/$product/prod/${product}.$PDY/$product.t${FH}z.stormsurge.ala3km.grib2
done


#RTOFS  v1.2
product=rtofs
COM=$COMROT/$product/$product.$PDY
mkdir -p $COM
cd $COM

#rtofs.20190903/rtofs_glo_3dz_f*_6hrly_hvr_US_east.nc

# FH - every 6 hours 006 to 192
if [[ $NOWCASTONLY == "YES" ]]; then
  FHList='006 012 018 024'
else
  FHList='006 012 018 024 030 036 042 048 054 060 066 072 078 084 090'
fi
for FH in $FHList
do
  echo "$NOMADS/com/$product/prod/${product}.$PDY/rtofs_glo_3dz_f${FH}_6hrly_hvr_US_east.nc"
  wget -nc $NOMADS/com/$product/prod/${product}.$PDY/rtofs_glo_3dz_f${FH}_6hrly_hvr_US_east.nc

done
# RTOFS v1.0.x
#/com/forcing/rtofs/rtofs.20201115/rtofs_glo_3dz_f*_6hrly_hvr_reg3.nc

# Get RTOFS for Alaska CIOFS
product=rtofs
COM=$COMROT/$product/$product.$PDATE
mkdir -p $COM
cd $COM

# FH - every 6 hours 006 to 192
# Why are we retrieving AK for previous cycle?
if [[ $NOWCASTONLY == "YES" ]]; then
  FHList='006 012 018 024'
else
  FHList='006 012 018 024 030 036 042 048 054 060 066 072 078 084 090'
fi
for FH in $FHList
do
  #/com/forcing/rtofs/rtofs.20201115/rtofs_glo_3dz_f*_6hrly_hvr_alaska.nc
  echo "$NOMADS/com/$product/prod/${product}.$PDATE/rtofs_glo_3dz_f${FH}_6hrly_hvr_alaska.nc"
  wget -nc $NOMADS/com/$product/prod/${product}.$PDATE/rtofs_glo_3dz_f${FH}_6hrly_hvr_alaska.nc

done

#CBOFS Restart - IS THE .INIT. the RESTART from PREVIOUS Cycle? Maybe!
#product=$OFS
#COM=$COMROT/$product.$PDY
#mkdir -p $COM
#dir -p $COM
#cd $COM

#HHList=''
#HHList='00 06 12 18'

# nos.cbofs.init.nowcast.20190904.t00z.nc 
# cbofs restart/init

#for HH in $HHList
#do
#  wget -nc https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/cbofs.$PDY/nos.cbofs.init.nowcast.$PDY.t${HH}z.nc
#done

# Get $cdate$cyc +6 hours init file, rename it to $cdate$cyc restart file
#NEXT=`$NDATE +6 ${CDATE}${cyc}`
#NCDATE=`echo $NEXT | cut -c1-8`
#ncyc=`echo $NEXT | cut -c9-10`
#
#nsfx=${NCDATE}.t${ncyc}z.nc
#
#if [[ $cyc -eq 18 ]] ; then
#  url=https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/${ofs}.$NCDATE
#fi
#
#ifile=${pfx}.init.nowcast.${nsfx}
#rfile=${pfx}.rst.nowcast.${sfx}
#
#wget -nc -nv ${url}/$ifile
#if [[ $? -ne 0 ]] ; then
#  echo "ERROR: Unable to retrieve $file from \n $url"
#  exit -1
#fi
#
# Rename it
#cp -p $ifile $rfile


# NAM
#/save/com/nos/ec2/cbofs.$PDY/nam/nam.$PDY/nam.t*.conusnest.hiresf*tm00.grib2_nos

# Forecast cycle
#HHList='00 06 12 18'  
#HH='18'
#HH='00'

## FH 00-60 avail every 6 hours 00-18z
if [[ $NOWCASTONLY == "YES" ]]; then
  FHList='00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24'
else
  FHList='00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29'
fi

product=nam
COM=$COMROT/$product/$product.$PDY
mkdir -p $COM
cd $COM

for FH in $FHList
do
  wget -nc $NOMADS/com/nam/prod/nam.$PDY/nam.t${HH}z.conusnest.hiresf${FH}.tm00.grib2
  ln -f nam.t${HH}z.conusnest.hiresf${FH}.tm00.grib2 nam.t${HH}z.conusnest.hiresf${FH}.tm00.grib2_nos
done


# NAM for Alaska region
#nam.t*.awp242*tm00.grib2
#nam.t06z.awp24200.tm00.grib2                16-Nov-2020 07:33   18M  
#nam.t06z.awp24203.tm00.grib2 

product=nam
COM=$COMROT/$product/$product.$PDY
mkdir -p $COM
cd $COM

#FHList='00 03 06 09 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84'
if [[ $NOWCASTONLY == "YES" ]]; then
  FHList='00 03 06 09 12 15 18 21 24'
else
  FHList='00 03 06 09 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84'
fi

for FH in $FHList
do
  wget -nc $NOMADS/com/nam/prod/nam.$PDY/nam.t${HH}z.awp242${FH}.tm00.grib2
  #ln -f nam.t${HH}z.awp242${FH}.tm00.grib2 nam.t${HH}z.awp242${FH}.tm00.grib2_nos
done

