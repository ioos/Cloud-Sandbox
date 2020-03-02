#!/bin/bash

version="v3.2.1"
noaaurl="https://www.nco.ncep.noaa.gov/pmb/codes/nwprod/nosofs.${version}"

opts="-nc -np -r"

fixdirs="
cbofs
dbofs
ngofs
negofs
nwgofs
leofs
shared
gomofs
tbofs
"


fixdirs='
sfbofs
lmhofs
ciofs
'

notdone='
wcofs
'

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
  aws s3 cp $tarfile s3://${bucket}/public/nosofs/fix/${tarfile}
  #https://ioos-cloud-sandbox.s3.amazonaws.com/public/nosofs/fix/cbofs.v3.2.1.fix.tgz
  rm $tarfile
done

