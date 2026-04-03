#!/usr/bin/env bash

mkdir -p /com/ec2-user/ufs_coastal/RT/NEMSfv3gfs/input-data-20250507
cd /com/ec2-user/ufs_coastal/RT/NEMSfv3gfs/input-data-20250507

if [ -d ROMS ]; then
  echo "It looks like we already have the input data ..."
  echo "... not downloading."
  exit 0
fi

aws s3 sync s3://ioos-transfers/UFS_coastal_app/ .

# [UFS-IOOS-Sandbox:/com/ec2-user/ufs_coastal/RT/NEMSfv3gfs/input-data-20250507] ec2-user tcsh> ls -1
# ROMS
# SCHISM

