#!/usr/bin/env bash
set -x

echo `date` > ~/setup.log

# RHEL8+
RUNUSER="ec2-user"

# CentOS 7 - Stream 8
#RUNUSER="centos"

BRANCH=main
#BRANCH=origin/x86_64
#BRANCH=origin/formainpr

EFS_VERS='v1.36.0'

# Mount the EFS volume

mkdir -p /mnt/efs/fs1
sudo yum -y -q install git 

sudo yum -y install amazon-efs-utils

if [ $? -ne 0 ]; then
  # Error: Unable to find a match: amazon-efs-utils
  # Alternate method
  sudo yum -y install rpm-build
  sudo yum -y install make
#  sudo yum -y install openssl-devel
#  sudo yum -y install cargo
#  sudo yum -y install rust
  cd /tmp
  git clone -b $EFS_VERS https://github.com/aws/efs-utils
  cd efs-utils
  sudo make rpm
  sudo yum -y install ./build/amazon-efs-utils*rpm
  cd /tmp
fi

mount -t nfs4 "${efs_name}:/" /mnt/efs/fs1
echo "${efs_name}:/ /mnt/efs/fs1 nfs defaults,_netdev 0 0" >> /etc/fstab

cd /mnt/efs/fs1
if [ ! -d save ] ; then
  sudo mkdir save
  sudo chgrp wheel save
  sudo chmod 777 save
  sudo ln -s /mnt/efs/fs1/save /save
fi

cd /mnt/efs/fs1/save
sudo mkdir $RUNUSER
sudo chown $RUNUSER:$RUNUSER $RUNUSER
cd $RUNUSER
sudo -u $RUNUSER git clone https://github.com/ioos/Cloud-Sandbox.git
cd Cloud-Sandbox
sudo -u $RUNUSER git checkout -t $BRANCH
cd scripts

# Need to pass ami_name
export ami_name=${ami_name}
echo "ami name : $ami_name"

# Install all of the software and drivers
sudo -E -u $RUNUSER ./setup-instance.sh >> ~/setup.log 2>&1

# TODO: Check for errors returned from any step above

echo "Installation completed!" >> ~/setup.log
echo `date` >> ~/setup.log
