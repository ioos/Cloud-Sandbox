#!/usr/bin/bash

#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

# Call this from the nosofs-NCO/fix folder

fixdirs="
shared
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

bucket=ioos-cloud-sandbox
version="v3.5.4"

url="https://${bucket}.s3.amazonaws.com/public/nosofs/fix"
for model in $fixdirs
do
  tarfile="${model}.${version}.fix.tgz"
  wget $url/$tarfile

  tar -xvf $tarfile
  rm $tarfile
done
