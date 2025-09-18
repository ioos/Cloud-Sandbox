#!/usr/bin/env bash

#nosofs_roms="cbofs ciofs dbofs gomofs tbofs wcofs"
#start_hr="00 

CDATE='20250918'

# wcofs is 03 all others 00, 06, 12, 18
HH='03'

# https://nomads.ncep.noaa.gov/pub/data/nccf/com/nosofs/prod/ciofs.20250918/ciofs.t00z.20250918.forecast.in
# ciofs.ocean.in

filename=$1

sed -i \
  -e "s/\.t${HH}z\.${CDATE}\./.t__HH__z.__CDATE__./g"                                     \
  -e "s/^[[:space:]]*NtileI == .*/     NtileI == __NTILEI__  ! I-direction partition/g"   \
  -e "s/^[[:space:]]*NtileJ == .*/     NtileJ == __NTILEJ__  ! J-direction partition/g"   \
  -e "s/^[[:space:]]*NTIMES == .*/     NTIMES == __NTIMES__/g"                            \
  -e "s/^[[:space:]]*DSTART = .*/     DSTART =  __DSTART__       ! days/g"                \
  -e "s/^[[:space:]]*TIDE_START = .*/     TIDE_START = __TIDE_START__   ! days/g"         \
  -e "s/^[[:space:]]*TIME_REF = .*/     TIME_REF = __TIME_REF__     ! yyyymmdd.dd/g"      \
  $filename

