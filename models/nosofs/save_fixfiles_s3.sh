#!/bin/bash
set -x

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

# Use this script to save fix files to an S3 bucket.
# These files are too large to store in a gitHub repo.

fix_version="v3.6.11"
nosofs_version="v3.6.6"
nosofsHOME=/save/patrick/nosofs.$nosofs_version
bucket="s3://ioos-sandbox-use2/public/nosofs/fix"

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

# Tar each one and save to S3
cd $nosofsHOME/fix

for dir in $fixdirs
do
  tarfile=$dir.${version}.fix.tgz
  tar -czvf $tarfile $dir
  aws s3 cp $tarfile ${bucket}/${tarfile}
  rm $tarfile
done

