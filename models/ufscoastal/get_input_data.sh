#!/usr/bin/env bash
set -eu
set -o pipefail

# We currently have ROMS Irene, and SCHISM Sandy test case data
mkdir -p /com/ufs-weather-model/RT/NEMSfv3gfs/input-data-20250507
cd /com/ufs-weather-model/RT/NEMSfv3gfs/input-data-20250507

if [ -d ROMS ]; then
  echo "It looks like we already have the input data ..."
  ls -al .
  echo "... not downloading."
  exit 0
fi

aws s3 sync s3://ioos-sandbox-use2/UFS_coastal_app/input-data-20250507 .

# S3 does not preserve file attributes
find . -name "*.sh" -exec chmod a+x {} \;

# Moved to glacier - aws s3 sync s3://ioos-transfers/UFS_coastal_app/ .

# [UFS-Sandbox-RHEL10:/com/ufs-weather-model/RT/NEMSfv3gfs/input-data-20250507] ec2-user tcsh> du -sk *
# 2028572	ROMS
# 110024	SCHISM


