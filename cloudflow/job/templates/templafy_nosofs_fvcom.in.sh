#!/usr/bin/env bash

nosofs_fvcom = "leofs lmhofs loofs lsofs ngofs2 sscofs sfbofs"

CDATE='20250917'
HH='03'

filename=$1

sed -i \
  -e "s/\.t${HH}z\.${CDATE}\./.t__HH__z.__CDATE__./g"                           \
  -e "s/.*DATE_REFERENCE.*/ DATE_REFERENCE  = '__DATE_REFERENCE__',/g"          \
  -e "s/.*START_DATE.*/ START_DATE      = '__START_DATE__ __HHMMSS__'/g"         \
  -e "s/.*END_DATE.*/ END_DATE        = '__END_DATE__ __END_HHMMSS__'/g"         \
  -e "s/.*RST_FIRST_OUT.*/ RST_FIRST_OUT    = '__START_DATE__ __HHMMSS__',/g"   \
  -e "s/.*NC_FIRST_OUT.*/ NC_FIRST_OUT    = '__START_DATE__ __HHMMSS__',/g"     \
  -e "s/.*NCSF_FIRST_OUT.*/ NCSF_FIRST_OUT    = '__START_DATE__ __HHMMSS__',/g" \
  $filename

