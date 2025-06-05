#!/bin/bash
# set -x

# This will retrieve the various fixed field datasets from S3 or other storage.
# These filesets are too large to store on GitHhub.

# forcing goes in: LO_output
# restart file and forecast output goes in: LO_roms

datasets='
  LO_data.grids.cas6.v1.3.tgz
  LO_data.grids.cas7.v1.3.tgz
  LO_roms.f2012.10.07.restart.cas7.tgz
  LO_output.forcing.cas7.f2012.10.08-f2012.10.09.tgz
'
bucket="ioos-sandbox-use2/public/LiveOcean"

COMDIR=/com/$(basename $(dirname $PWD))
if [ ! -d $COMDIR ]; then
  mkdir -p $COMDIR
fi

cd $COMDIR || exit -1

for file in $datasets
do
  key=$file

  # Default behavior is to retrieve (no args)
  if [[ $# -eq 1 && $1 == 'store' ]] ; then
    aws s3 cp $file s3://${bucket}/${key}
  else
    aws s3 cp s3://${bucket}/${key} .
    tar -xvf $file
    rm $file
  fi
done

