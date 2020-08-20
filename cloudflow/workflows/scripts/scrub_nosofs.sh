#!/bin/bash

#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

#. /usr/share/Modules/init/bash
#module load gcc
#module load produtils

# Scrub forcing older than 1 day - can redownload from UW
# Scrub foreast data

COMROT=/com/nos
COMVERIF=/com/nos-noaa

today=`date -u +%Y%m%d`

YYYY=${today:0:4}
MM=${today:4:2}
DD=${today:6:2}

#echo $today


##############################################################################
# Delete plots folders older than n days - these have been sent to S3
##############################################################################
daysoldplots=1

echo "Deleting old plots"
cd $COMROT/plots
find . -depth -name "[A-Za-z0-9]*" -type d -daystart -mtime +$daysoldplots
find . -depth -name "[A-Za-z0-9]*" -type d -daystart -mtime +$daysoldplots -exec rm -Rf {} \;



##############################################################################
# Delete forecast folders older than n days
##############################################################################
daysoldfcst=14

echo "Deleting forecast directories older than $daysoldfcst days"
cd $COMROT
# regex matches ./cbofs.2020081800, ./sfbofs.2020081803, etc.
REGEX="./[a-z]*ofs.*[0-1][0-9][0-3][0-9][0-9][0-9]"
find . -depth -type d -daystart -mtime +$daysoldfcst -path "$REGEX"
find . -depth -type d -daystart -mtime +$daysoldfcst -path "$REGEX" -exec rm -Rf {} \;



##############################################################################
# Delete verification data older than 1 day
##############################################################################
daysoldics=0

echo "Deleting verification data older than $daysoldics days"
cd $COMVERIF
# regex matches ./cbofs.2020081800, ./sfbofs.2020081803, etc.
REGEX="./[a-z]*ofs.*[0-1][0-9][0-3][0-9][0-9][0-9]"
find . -depth -type d -daystart -mtime +$daysoldfcst -path "$REGEX"
find . -depth -type d -daystart -mtime +$daysoldfcst -path "$REGEX" -exec rm -Rf {} \;

