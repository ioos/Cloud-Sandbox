#!/bin/bash

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


version="v3.5.4"
noaaurl="https://www.nco.ncep.noaa.gov/pmb/codes/nwprod/nosofs.${version}"

opts="-nc -np -r"

fixdirs="
cbofs
ciofs
creofs
dbofs
gomofs
leofs
lmhofs
loofs
lsofs
ngofs2
sfbofs
tbofs
wcofs
"
# shared

#fixdirs='
#shared
#'

for dir in $fixdirs
do
  wget $opts $noaaurl/fix/$dir/
done

cd www.nco.ncep.noaa.gov
rm robots.txt
find . -name "index.html*" -exec rm -rf {} \;
cd ..

rm -Rf nosofs.${version}

mv ./www.nco.ncep.noaa.gov/pmb/codes/nwprod/nosofs.${version} .
rm -Rf www.nco.ncep.noaa.gov

# Tar it and save to S3
cd nosofs.${version}/fix

bucket="ioos-cloud-sandbox"

for dir in $fixdirs
do
  tarfile=$dir.${version}.fix.tgz
  tar -czvf $tarfile $dir
  aws s3 cp $tarfile s3://${bucket}/public/nosofs/fix/${tarfile} --acl public-read
  #https://ioos-cloud-sandbox.s3.amazonaws.com/public/nosofs/fix/cbofs.v3.2.1.fix.tgz
  rm $tarfile
done

