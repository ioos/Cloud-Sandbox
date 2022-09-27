#!/usr/bin/env bash

echo `date` > /tmp/setup.log

# AMZ linux and some other AMIs use ec2-user. CentOS 7 usese centos

# RUNUSER="ec2-user"
RUNUSER="centos"

mkdir -p /mnt/efs/fs1
sudo yum -y -q install git 

sudo yum -y install amazon-efs-utils

if [ $? -ne 0 ]; then
  # Error: Unable to find a match: amazon-efs-utils
  # Alternate method
  sudo yum -y install rpm-build
  cd /tmp
  git clone https://github.com/aws/efs-utils
  cd efs-utils
  sudo yum -y install make
  sudo yum -y install rpm-build
  sudo make rpm
  sudo yum -y install ./build/amazon-efs-utils*rpm
  cd /tmp
fi

mount -t nfs4 "${efs_name}:/" /mnt/efs/fs1
echo "${efs_name}:/ /mnt/efs/fs1 nfs defaults,_netdev 0 0" >> /etc/fstab

cd /home/$RUNUSER
sudo -u $RUNUSER git clone https://github.com/ioos/Cloud-Sandbox.git
cd Cloud-Sandbox/cloudflow/workflows/scripts

BRANCH=master

sudo -u $RUNUSER git checkout $BRANCH

# Need to pass ami_name
export ami_name=${ami_name}
echo "ami name : $ami_name"

sudo -E -u $RUNUSER ./setup-instance.sh >> /tmp/setup.log 2>&1

# TODO: Check for errors returned from any step above

echo "Installation completed!" >> /tmp/setup.log
echo `date` >> /tmp/setup.log
