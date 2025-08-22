#!/usr/bin/env bash
set -e

# Available from s3://ioos-sandbox-use2/public/
# hindcast.201901.input.tgz - 31GB

# Set this as needed for proper folders for your user

SBUSER=$USER
INSTALLDIR=/com/$SBUSER/necofs/NECOFS_v2.4/hindcast

BUCKETPRE=ioos-sandbox-use2/public/necofs
FILE=necofs.20190101.input.tgz

echo "Installing in: $INSTALLDIR"

if [ ! -d $INSTALLDIR ]; then
    mkdir -p $INSTALLDIR
fi

cd $INSTALLDIR || exit 1

# Only fetch it if it doesn't already exist
if [ ! -d necofs.20190101 ]; then
  aws s3 cp s3://${BUCKETPRE}/${FILE} .
  tar -xvf $FILE

  # Everything should now be in the hindcasts/201901 folder, ready to run the workflow
  echo "Test case input files should now be available in $INSTALLDIR/necofs.20190101/input"
  rm $FILE
else
  echo "It looks like there is already data present for $INSTALLDIR/necofs.20190101/input"
  echo "Not downloading the testcase data"
fi
