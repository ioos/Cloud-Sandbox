#!/usr/bin/env bash

# https://github.com/aws/efs-utils/blob/v2.3.3/README.md

EFS_VERS=v2.3.3
# v2 supports TSL encryption
sudo yum -y install rpm-build
sudo yum -y install make
sudo yum -y install nfs-utils
sudo yum -y install openssl-devel
sudo yum -y install cargo
sudo yum -y install rust
sudo yum -y install stunnel

cd /tmp
git clone -b $EFS_VERS https://github.com/aws/efs-utils
cd efs-utils
sudo make rpm
sudo yum -y install ./build/amazon-efs-utils*rpm
cd /tmp


