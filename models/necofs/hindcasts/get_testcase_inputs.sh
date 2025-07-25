#!/usr/bin/env bash
set -e

# Available from s3://ioos-sandbox-use2/public/
# hindcast.201901.input.tgz - 31GB

# Set this as needed for proper folders for your user

SBUSER=$USER
INSTALLDIR=/com/$SBUSER/necofs/NECOFS_v2.4

echo "Installing in: $INSTALLDIR"

if [ ! -d $INSTALLDIR ]; then
    mkdir -p $INSTALLDIR
fi

cd $INSTALLDIR || exit 1

# Only fetch it if it doesn't already exist
if [ ! -d hindcasts/201901 ]; then
  aws s3 cp s3://ioos-sandbox-use2/public/necofs/hindcast.201901.input.tgz .
  tar -xvf hindcast.201901.input.tgz

  # Everything should now be in the hindcasts/201901 folder, ready to run the workflow
  echo "Test case input files should now be available in $INSTALLDIR/hindcasts/201901"
  rm hindcast.201901.input.tgz
else
  echo "It looks like there is already data present for $INSTALLDIR/hindcasts/201901"
  echo "Not downloading the testcase data"
fi
