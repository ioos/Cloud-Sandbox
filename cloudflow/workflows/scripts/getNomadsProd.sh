#!/bin/bash
set -x

#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

if [ $# -lt 3 ] ; then
  echo "Usage: $0 cbofs|ngofs|etc. yyyymmdd hh [/com/nos-noaa/cbofs.20200416 | other destination]"
  exit 1
fi


OFS=$1
CDATE=$2
CYC=$3

if [ $# -gt 3 ]; then
  dest=$4
else
  dest=${OFS}.${CDATE}
fi

err=0

mkdir -p $dest
cd $dest
  

NOMADS=https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/$OFS.$CDATE

# Download every hour forecast
###############################################################
hlist='00 01 02 03 04 05 06 07 08 09'

# Most forecasts are 48 hours, with some exceptions
ehr=48
case $OFS in
    gomofs )
    ehr=72
    ;;
    ngofs)
    ehr=54
    ;;
    leofs)
    ehr=120
    ;;
esac


for hh in $hlist
do
  wget -nc $NOMADS/nos.$OFS.fields.f0$hh.$CDATE.t${CYC}z.nc
  ((err += $?))
done

hh=10
while [ $hh -le $ehr ]
do
  if [ $hh -lt 100 ] ; then
    hhstr="0$hh"
  else
    hhstr="$hh"
  fi
  wget -nc $NOMADS/nos.$OFS.fields.f$hhstr.$CDATE.t${CYC}z.nc
  ((err += $?))
  ((hh += 1))
done
###############################################################

# Get the nestnode files if ngofs
if [[ $OFS == "ngofs" ]] ; then
  # nos.nwgofs.obc.20191218.t03z.nc  
  wget -nc $NOMADS/../negofs.${CDATE}/nos.negofs.obc.$CDATE.t${CYC}z.nc
  ((err += $?))
  mv nos.negofs.obc.$CDATE.t${CYC}z.nc nos.ngofs.nestnode.negofs.forecast.$CDATE.t${CYC}z.nc

  wget -nc $NOMADS/../nwgofs.${CDATE}/nos.nwgofs.obc.$CDATE.t${CYC}z.nc
  ((err += $?))
  mv nos.nwgofs.obc.$CDATE.t${CYC}z.nc nos.ngofs.nestnode.nwgofs.forecast.$CDATE.t${CYC}z.nc
fi

# Get the log and .in config files
wget -nc $NOMADS/nos.$OFS.forecast.$CDATE.t${CYC}z.in
((err += $?))
wget -nc $NOMADS/nos.$OFS.forecast.$CDATE.t${CYC}z.log
((err += $?))

if [ $err -eq 0 ] ; then
  exit 0
else
  exit $err
fi
