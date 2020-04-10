#!/bin/sh -x

if [[ $(uname) == "Darwin" ]] ; then
  # BSD/Mac date
  CURDATE=`date -j "+%Y%m%d"`
  PREDATE=`date -j -v-1d "+%Y%m%d"`
else
  # Linux/Gnu
  CURDATE=`date -u "+%Y%m%d"`
  PREDATE=`date -u -d "1 day ago" +%Y%m%d`
fi

# https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/cbofs.20191021/
NOMADS=https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod

# cbofs.status shows most recent forecast/cycle date
#echo curl $NOMADS/cbofs.$CURDATE/cbofs.status
curcycle=`curl -s $NOMADS/cbofs.$CURDATE/cbofs.status`

#echo "Current cycle is $curcycle"
echo $curcycle
