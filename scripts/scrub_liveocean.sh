#!/bin/bash

#__copyright__ = "Copyright © 2025 Tetra Tech, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


#. /usr/share/Modules/init/bash
#module load gcc
#module load produtils

# Scrub forcing older than 1 day - can redownload from UW
# Scrub foreast data

COMROT=/com/liveocean
COMVERIF=/com/liveocean-uw

today=`date -u +%Y%m%d`

YYYY=${today:0:4}
MM=${today:4:2}
DD=${today:6:2}

#echo $today


##############################################################################
# Delete plots folders older than 1 day - these have been sent to S3
##############################################################################
daysoldplots=1

echo "Deleting old plots"
if [ -d $COMROT/plots ]; then
  cd $COMROT/plots
  find . -depth -name "[A-Za-z0-9]*" -type d -daystart -mtime +$daysoldplots
  find . -depth -name "[A-Za-z0-9]*" -type d -daystart -mtime +$daysoldplots -exec rm -Rf {} \;
fi



##############################################################################
# Delete forecast folders older than 1 week
##############################################################################
daysoldfcst=6

echo "Deleting forecast directories older than $daysoldfcst days"
if [ -d $COMROT ]; then
  cd $COMROT
  find . -depth -type d -daystart -mtime +$daysoldfcst -path "./f${YYYY}.[0-1][0-9].[0-3][0-9]"
  find . -depth -type d -daystart -mtime +$daysoldfcst -path "./f${YYYY}.[0-1][0-9].[0-3][0-9]" -exec rm -Rf {} \;
  #find . -depth -type d -daystart -mtime +$daysoldfcst -path "./f${YYYY}.[0-1][0-9].[0-3][0-9]" -delete
fi


##############################################################################
# Delete forcing/ICs older than 1 day
##############################################################################
daysoldics=0

echo "Deleting forcing/ICs directories older than $daysoldics days"
if [ -d $COMROT/forcing ]; then
  cd $COMROT/forcing
  find . -depth -type d -daystart -mtime +$daysoldics -path "./f${YYYY}.[0-1][0-9].[0-3][0-9]"
  find . -depth -type d -daystart -mtime +$daysoldics -path "./f${YYYY}.[0-1][0-9].[0-3][0-9]" -exec rm -Rf {} \;
  #find . -depth -type d -daystart -mtime +$daysoldics -path "./f${YYYY}.[0-1][0-9].[0-3][0-9]" -delete
fi


##############################################################################
# Delete verification data older than 1 day
##############################################################################
daysoldics=0

echo "Deleting verification data older than $daysoldics days"
if [ -d $COMVERIF ]; then
  cd $COMVERIF
  find . -depth -type d -daystart -mtime +$daysoldics -path "./f${YYYY}.[0-1][0-9].[0-3][0-9]"
  find . -depth -type d -daystart -mtime +$daysoldics -path "./f${YYYY}.[0-1][0-9].[0-3][0-9]" -exec rm -Rf {} \;
fi



##############################################################################
# Only keep forecast output for hours 01-25 for more than 1 day
##############################################################################
daysoldfcst24=1

echo "Deleting forecast data greater than forecast hour 25 older than $daysoldfcst24 days"
if [ -d $COMROT ]; then
  cd $COMROT
  # f2020.02.03
  # ocean_his_0026.nc
  dirlist=`find . -type d -path "./f${YYYY}.[0-1][0-9].[0-3][0-9]"`
  fhrstart=26
  fhrend=73
  prfx="ocean_his_00"
  sufx=".nc"

  secsinday=86400
  maxage=$((($daysoldfcst24 + 1) * $secsinday))
  now=`date +%s`
  
  for dir in $dirlist
  do
    fhr=$fhrstart
    while [ $fhr -le $fhrend ]
    do
      file=$dir/${prfx}${fhr}${sufx}
      if [ -f $file ]; then 
        fdate=`stat --format="%Y" $file`
        age=$((${now}-${fdate}))
        if [ $age -gt $maxage ] ; then
          ls $file
          rm -f $file
        fi
      fi
    
      fhr=$((fhr+=1))
    done
  done

