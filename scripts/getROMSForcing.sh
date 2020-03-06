#!/bin/sh
# This receives the forcing data required to run CBOFS prep step
# It needs to be modified to support any ROMS based model

NOMADS=https://nomads.ncep.noaa.gov/pub/data/nccf
#cd $COMOUT

# Get current cycle forcing data
PDY=20191028

# Get previous cycle for init time, need some overlap
#PDY=20190905

#ETSS - storm surge
product=etss
COM=/save/com/$product/ec2/$product.$PDY
mkdir -p $COM
cd $COM

# 00z to 18z available
FHList='00 06 12 18'

for FH in $FHList
do
  # etss.t18z.stormsurge.con2p5km.grib2  
  wget -nc $NOMADS/com/$product/prod/${product}.$PDY/$product.t${FH}z.stormsurge.con2p5km.grib2
done

#RTOFS  v1.2
product=rtofs

mkdir -p /save/com/$product/ec2/$product.$PDY
cd /save/com/$product/ec2/$product.$PDY
#rtofs.20190903/rtofs_glo_3dz_f*_6hrly_hvr_US_east.nc

# FH - every 6 hours 006 to 192
FHList='006 012 018 024 030 036 042 048 054 060'
for FH in $FHList
do
  echo "$NOMADS/com/$product/prod/${product}.$PDY/rtofs_glo_3dz_f${FH}_6hrly_hvr_US_east.nc"
  wget -nc $NOMADS/com/$product/prod/${product}.$PDY/rtofs_glo_3dz_f${FH}_6hrly_hvr_US_east.nc

done
#              com/rtofs/prod/rtofs.20190904/

#CBOFS Restart - IS THE .INIT. the RESTART from PREVIOUS Cycle? Maybe!
mkdir -p /save/com/nos/ec2/cbofs.$PDY
cd /save/com/nos/ec2/cbofs.$PDY
HHList=''
HHList='00 06 12 18'


# nos.cbofs.init.nowcast.20190904.t00z.nc 
# cbofs restart/init

for HH in $HHList
do

  wget -nc https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/cbofs.$PDY/nos.cbofs.init.nowcast.$PDY.t${HH}z.nc
  #ln -f  nos.cbofs.init.nowcast.$PDY.t${HH}z.nc nos.cbofs.rst.nowcast.$PDY.t${HH}z.nc

done



# NAM
#/save/com/nos/ec2/cbofs.$PDY/nam/nam.$PDY/nam.t*.conusnest.hiresf*tm00.grib2_nos

# Forecast cycle
#HHList='00 06 12 18'  
#HH='18'
HH='00'

## FH 00-60 avail every 6 hours 00-18z
#FHList='00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24'
#FHList=''


mkdir -p /save/com/nam/ec2/nam.$PDY
cd /save/com/nam/ec2/nam.$PDY

for FH in $FHList
do
  wget -nc $NOMADS/com/nam/prod/nam.$PDY/nam.t${HH}z.conusnest.hiresf${FH}.tm00.grib2
  ln -f nam.t${HH}z.conusnest.hiresf${FH}.tm00.grib2 nam.t${HH}z.conusnest.hiresf${FH}.tm00.grib2_nos

done
