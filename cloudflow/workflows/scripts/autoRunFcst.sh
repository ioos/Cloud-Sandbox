#!/bin/sh -xa

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


startdir=$PWD

. /usr/share/Modules/init/sh
module load produtil
module load gcc

COMDIR=/noscrub/com/nos
NOSDIR=/save/nosofs.v3.1.9.1

curcycle=$(./getCurrentCycleOps.sh)
prevcycle=$(ndate -6 $curcycle)

echo Current: $curcycle
echo Previous: $prevcycle

echo "Fetching ICs for $prevcycle"
cdate=$(echo $prevcycle | cut -c1-8)
cyc=$(echo $prevcycle | cut -c9-10)

romsin=nos.cbofs.forecast.${cdate}.t${cyc}z.in
romssave=nos.cbofs.forecast.${cdate}.t${cyc}z.in.save

if [ -s $COMDIR/cbofs.$cdate/$romsin ] ; then
  rm $COMDIR/cbofs.$cdate/$romsin
fi

# Get the ICs
./getICs_cbofs.sh $cdate $cyc

# Change the roms.in file, tiles and run length
cd $COMDIR/cbofs.$cdate

cp -p $romsin $romssave

# NtileI == 10
# NtileJ == 14
# NTIMES == 34560   # 48 hours

Itiles=8
Jtiles=12
NTIMES=4320   # 6 hours

#Itiles=4
#Jtiles=4
#NTIMES=720   # 1 hour

# Replace tiles and ntimes with custom setting
# Order seems to be important

sed -i "s/NtileI == 10/NtileI == $Itiles/" $romsin
sed -i "s/NtileJ == 14/NtileJ == $Jtiles/" $romsin
sed -i "s/NTIMES == 34560/NTIMES == $NTIMES/" $romsin

# Launch the forecast
export NPP=$(($Itiles * $Jtiles))

cd $NOSDIR/jobs
./fcstrun.sh $cdate $cyc

# Copy results to S3 bucket using aws-cli
cd $startdir
./copyResults2S3.sh $COMDIR $cdate $cyc


