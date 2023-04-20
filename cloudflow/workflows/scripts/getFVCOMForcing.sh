#!/bin/sh
set -x

# NOTE: The full forcing dataset is 75GB
#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


#https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/cbofs.$PDY/

SCRS=$PWD

NOMADS=https://nomads.ncep.noaa.gov/pub/data/nccf/com
COMDIR=/com/forcing

# Get current cycle forcing data
PDY=20201119
cyc=06    # Only used for restart
#lmhofs 00,06,12,18

# Get previous cycle for init time, need some overlap
#PDY=20190905

# For full prep:
# Need NAM previous cycle fhr 0-6, NAM current cycle fhr 0-60
# RTOFS is once per day run, will need previous day if running 03z or 00z nowcast
# LMHOFS Needs GFS25

product=gfs
# /com/forcing/gfs/gfs.20201116/*/gfs.t*.pgrb2.0p50.f???
CYC='06'
mkdir -p $COMDIR/$product/$product.$PDY/$CYC
cd $COMDIR/$product/$product.$PDY/$CYC

#gfs.t06z.pgrb2.0p50.f000
#gfs.t06z.pgrb2.0p50.f003
#gfs.t06z.pgrb2.0p50.f006

# Get 60 hour forecast
#FHList=`$SCRS/hhlist.sh 1 60`
FHList=`$SCRS/hhlist.sh 3 72 000`
for FH in $FHList
do
  fileurl="$NOMADS/$product/prod/${product}.$PDY/${CYC}/gfs.t${CYC}z.pgrb2.0p50.f${FH}"
  echo $fileurl
  wget -nc $fileurl
done

#RTOFS  v1.2
product=rtofs

mkdir -p $COMDIR/$product/$product.$PDY
cd $COMDIR/$product/$product.$PDY
#rtofs.20190903/rtofs_glo_3dz_f*_6hrly_hvr_US_east.nc
# rtofs_glo_2ds_f*_3hrly_diag.nc
# NGOFS reg1

# Get 60 hour forecast
#FHList=`$SCRS/hhlist.sh 1 60`
FHList=`$SCRS/hhlist.sh 6 96 000`
for FH in $FHList
do
  echo "$NOMADS/$product/prod/${product}.$PDY/rtofs_glo_3dz_f${FH}_6hrly_hvr_US_east.nc"
  wget -nc $NOMADS/$product/prod/${product}.$PDY/rtofs_glo_3dz_f${FH}_6hrly_hvr_US_east.nc
done

FHList=`$SCRS/hhlist.sh 3 72 000`
for FH in $FHList
do
  wget -nc $NOMADS/$product/prod/${product}.$PDY/rtofs_glo_2ds_f${FH}_3hrly_diag.nc
done

# NAM
#com/nos/ec2/cbofs.$PDY/nam/nam.$PDY/nam.t*.conusnest.hiresf*tm00.grib2_nos

product=nam

# Forecast cycle
FHList=`$SCRS/hhlist.sh 1 60`
HH="06"
mkdir -p $COMDIR/$product/$product.$PDY
cd $COMDIR/$product/$product.$PDY

for FH in $FHList
do
                  #/nam/prod/nam.20191028/nam.t00z.conusnest.hiresf02.tm00.grib2
  wget -nc $NOMADS/$product/prod/nam.$PDY/nam.t${HH}z.conusnest.hiresf${FH}.tm00.grib2
  ln -f nam.t${HH}z.conusnest.hiresf${FH}.tm00.grib2 nam.t${HH}z.conusnest.hiresf${FH}.tm00.grib2_nos
done

# Get restart file
# RST_FILE=/data/com/nos//ngofs.20191027/nos.ngofs.rst.nowcast.20191027.t23z.nc
#cp -p nos.ngofs.init.nowcast.20191028.t09z.nc nos.ngofs.rst.nowcast.20191028.t03z.nc 

# Prep will fail if the expected restart file is missing
# Add this (copy from get ICs scripts"
#cd ngofs.20191028/
#wget https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/ngofs.20191028/nos.ngofs.init.nowcast.20191028.t09z.nc
#cp -p nos.ngofs.init.nowcast.20191028.t09z.nc nos.ngofs.rst.nowcast.20191028.t03z.nc
