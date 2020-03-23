#!/usr/bin/bash

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

fixdirs='negofs'

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
