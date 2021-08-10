#!/usr/bin/bash

#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

fixdirs="
shared
leofs
cbofs
dbofs
ngofs
negofs
nwgofs
gomofs
tbofs
sfbofs
lmhofs
ciofs
"

fixdirs='shared ciofs'

bucket=ioos-cloud-sandbox
version=v3.2.1

url="https://${bucket}.s3.amazonaws.com/public/nosofs/fix"
for model in $fixdirs
do
  tarfile="${model}.${version}.fix.tgz"
  wget $url/$tarfile

  tar -xvf $tarfile
  rm $tarfile
done
