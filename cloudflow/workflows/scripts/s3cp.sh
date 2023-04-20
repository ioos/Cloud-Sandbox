#!/bin/bash
#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


flist='
cbofs.v3.2.1.fix.tgz
negofs..v3.2.1.fix.tgz
ngofs.v3.2.1.fix.tgz
nwgofs..v3.2.1.fix.tgz
shared.v3.2.1.fix.tgz
'

bucket="s3://ioos-cloud-sandbox/public/nosofs/fix"

for file in $flist
do

  aws s3 cp $file $bucket/$file

done

