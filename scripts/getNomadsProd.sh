#!/bin/sh

# Retrieve 48 hour forecast from NOAA

if [ $# -lt 3 ] ; then
  echo "Usage: $0 cbofs|ngofs|etc. yyyymmdd hh [destination path]"
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

mkdir -p $dest
cd $dest
  

#nos.$OFS.fields.f001.$CDATE.t${CYC}z.nc 
NOMADS=https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/$OFS.$CDATE

hlist='01 02 03 04 05 06 07 08 09'
#hlist='01 06 12 18 24 36 48'

for hh in $hlist
do
  wget -nc $NOMADS/nos.$OFS.fields.f0$hh.$CDATE.t${CYC}z.nc
done

hh=10
ehr=48
while [ $hh -le $ehr ]
do
  wget -nc $NOMADS/nos.$OFS.fields.f0$hh.$CDATE.t${CYC}z.nc
  ((hh += 1))
done


if [[ $OFS == "ngofs" ]] ; then
  # nos.nwgofs.obc.20191218.t03z.nc  
  wget -nc $NOMADS/../negofs.${CDATE}/nos.negofs.obc.$CDATE.t${CYC}z.nc
  mv nos.negofs.obc.$CDATE.t${CYC}z.nc nos.ngofs.nestnode.negofs.forecast.$CDATE.t${CYC}z.nc

  wget -nc $NOMADS/../nwgofs.${CDATE}/nos.nwgofs.obc.$CDATE.t${CYC}z.nc
  mv nos.nwgofs.obc.$CDATE.t${CYC}z.nc nos.ngofs.nestnode.nwgofs.forecast.$CDATE.t${CYC}z.nc
fi



#hh=10
#while [ $hh -le 48 ] ; do
#  wget -nc $NOMADS/nos.$OFS.fields.f0$hh.$CDATE.t${CYC}z.nc
#  hh=$(($hh+1))
#done

wget -nc $NOMADS/nos.$OFS.forecast.$CDATE.t${CYC}z.in
wget -nc $NOMADS/nos.$OFS.forecast.$CDATE.t${CYC}z.log

