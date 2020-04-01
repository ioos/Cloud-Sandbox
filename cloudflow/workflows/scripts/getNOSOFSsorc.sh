#!/bin/bash

#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

version="v3.2.1"
noaaurl="https://www.nco.ncep.noaa.gov/pmb/codes/nwprod/nosofs.${version}"

opts="-nc -np -r"

fixdirs="
fix/cbofs/
fix/ngofs/
fix/negofs/
fix/nwgofs/
fix/shared/
"

srcdirs="
ecf/
jobs/
lsf/
modulefiles/
parm/
scripts/
sorc/
ush/"

for dir in $srcdirs
do
  wget $opts $noaaurl/$dir
done

for dir in $fixdirs
do
  wget $opts $noaaurl/$dir
done


cd www.nco.ncep.noaa.gov
rm robots.txt
find . -name "index.html*" -exec rm -rf {} \;

mv www.nco.ncep.noaa.gov/pmb/codes/nwprod/nosofs.${version} .
rm -Rf www.nco.ncep.noaa.gov

