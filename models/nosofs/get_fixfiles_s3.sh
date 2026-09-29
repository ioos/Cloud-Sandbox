#!/usr/bin/bash

#__copyright__ = "Copyright © 2026 Tetra Tech, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

# Call this from the nosofs.<version>/fix folder

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
'

# Optionally only download some
#fixdirs='shared cbofs leofs'
fixdirs='
ciofs
dbofs
gomofs
lmhofs
loofs
lsofs
ngofs2
sfbofs
sscofs
tbofs
wcofs
'

bucket=ioos-sandbox-use2
version="v3.6.11"

echo "Change this folder according to your setup"
echo "cd /save/$USER/nosofs.v3.6.6/fix"
cd /save/$USER/nosofs.v3.6.6/fix

url="https://${bucket}.s3.amazonaws.com/public/nosofs/fix"
for model in $fixdirs
do
  tarfile="${model}.${version}.fix.tgz"
  wget $url/$tarfile

  tar -xvf $tarfile
  rm $tarfile
done

echo "You might neet to copy folders to your nosofs fix folder"
echo "e.g."
echo "mv wcofs /save/$USER/nosofs.v3.6.6/fix"
