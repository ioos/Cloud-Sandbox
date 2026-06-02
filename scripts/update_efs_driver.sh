#!/usr/bin/env bash


EFS_VERS='v3.1.1'
# EFS_VERS='v2.3.3'
# EFS v3 adds s3files support - no breaking changes with v2 - problems building on RHEL8.10
# EFS v2 supports TSL encryption

sudo mkdir -p /mnt/efs/fs1

## Install EFS utilities
########################
# https://github.com/aws/efs-utils/blob/v2.3.3/README.md
# sudo yum -y install amazon-efs-utils
# Some Linux distributions: Unable to find a match: amazon-efs-utils

# Alternate method, build from source
# Install prerequisites
sudo yum -y -q install git
sudo yum -y install rpm-build
sudo yum -y install make
sudo yum -y install nfs-utils
sudo yum -y install openssl-devel
sudo yum -y install cargo
sudo yum -y install golang
sudo yum -y install perl
sudo yum -y install rust
sudo yum -y install stunnel

cd /tmp
if [ -d efs-utils ]; then
  rm -Rf efs-utils
fi

git clone -b $EFS_VERS https://github.com/aws/efs-utils
cd efs-utils
make rpm
sudo yum -y install ./build/amazon-efs-utils*rpm
cd /tmp


