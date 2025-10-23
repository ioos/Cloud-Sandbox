#!/usr/bin/bash

#__copyright__ = "Copyright © 2025 Tetra Techx. All rights reserved."
#__license__ = "BSD 3-Clause"

# Call this from the nosofs-NCO/fix folder

fixdirs='
eccofs
'

# Optionally only download some
#fixdirs='shared cbofs'

bucket=ioos-sandbox-use2
version="v3.6.6_dev"

url="https://${bucket}.s3.amazonaws.com/public/nosofs/fix"
for model in $fixdirs
do
  tarfile="${model}.${version}.fix.tgz"
  wget $url/$tarfile

  tar -xvf $tarfile
  rm $tarfile
done
