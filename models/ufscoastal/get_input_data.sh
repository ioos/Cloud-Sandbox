#!/usr/bin/env bash
set -eu
set -o pipefail

# We currently have ROMS Irene, and SCHISM Sandy test case data
mkdir -p /com/ufs-weather-model/RT/NEMSfv3gfs/input-data-20250507
cd /com/ufs-weather-model/RT/NEMSfv3gfs/input-data-20250507

if [ -d ROMS ]; then
  echo "It looks like we already have the input data ..."
  echo "... not downloading."
  exit 0
fi

# TODO: Also mirror this data to TT/IOOS S3
aws s3 sync s3://ioos-transfers/UFS_coastal_app/ .

# [UFS-IOOS-Sandbox:/com/ec2-user/ufs-weather-model/RT/NEMSfv3gfs/input-data-20250507] ec2-user tcsh> ls -1
# ROMS
# SCHISM

