#!/usr/bin/bash

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

# Call this from the nosofs-NCO/fix folder

fixdirs='
shared
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
eccofs
'

# Optionally only download some
#fixdirs='shared cbofs'

bucket=ioos-sandbox-use2
version="v3.6.11"

url="https://${bucket}.s3.amazonaws.com/public/nosofs/fix"
for model in $fixdirs
do
  tarfile="${model}.${version}.fix.tgz"
  wget $url/$tarfile

  tar -xvf $tarfile
  rm $tarfile
done
