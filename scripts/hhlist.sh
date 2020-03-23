#!/bin/sh

if [ $# -lt 2 ] ; then
  echo "Usage $0 : increment max [optional 000 format]"
  exit
fi

hinc=$1
hhe=$2

format=${3:-"00"} 

#echo "format is $format"


hhs=0

hh=$hhs
hhlist=""

while [ $hh -le $hhe ] ; do

  if [[ $format == "000" ]] ; then
    # Will not work for 100+ hours
    if [ $hh -lt 10 ] ; then 
      hhlist="$hhlist 00$hh"
    else
      hhlist="$hhlist 0$hh"
    fi
  else
    if [ $hh -lt 10 ] ; then
      hhlist="$hhlist 0$hh"
    else
      hhlist="$hhlist $hh"
    fi
  fi

  hh=$((hh + hinc))
done

echo $hhlist
