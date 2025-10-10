#!/bin/bash
set -x

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

# Use this script update the fixed fields files to the current operational version
# and save to an S3 bucket.
# These files are too large to store in a gitHub repo.


version="v3.6.11"
noaaurl="https://www.nco.ncep.noaa.gov/pmb/codes/nwprod/nosofs.${version}"

opts="-nc -np -r"

fixdirs='
cbofs
ciofs
dbofs
gomofs
leofs
lmhofs
loofs
lsofs
ngofs2
sfbofs
sscofs
tbofs
wcofs
wcofs_da
wcofs_free
shared
'

fixdirs='eccofs'

# Tar each one and save to S3
cd nosofs.${version}/fix

bucket="ioos-sandbox-use2"

for dir in $fixdirs
do
  tarfile=$dir.${version}.fix.tgz
  tar -czvf $tarfile $dir
  aws s3 cp $tarfile s3://${bucket}/public/nosofs/fix/${tarfile}
  rm $tarfile
done

