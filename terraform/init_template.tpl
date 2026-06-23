#!/usr/bin/env bash
set -x

echo `date` > ~/setup.log

BRANCH=${sandbox_version}

RUNUSER="ec2-user"

EFS_VERS='v3.1.3'

# EFS_VERS 3.1.2 added RHEL 10 support"
# EFS v3 adds s3files support - no breaking changes with v2
# EFS v2 supports TSL encryption

sudo mkdir -p /mnt/efs/fs1

sudo dnf -y -q install git 

## Install EFS utilities
########################

cd /tmp
curl -s https://amazon-efs-utils.aws.com/efs-utils-installer.sh | sh -s -- --install

# Issues building from source on RHEL 10, the above works perfectly
# https://github.com/aws/efs-utils/
# dnf -y install amazon-efs-utils


## Mount the EFS volume
#######################

echo "efs_name: ${efs_name}"

mount -t efs "${efs_name}:/" /mnt/efs/fs1
echo "${efs_name}:/ /mnt/efs/fs1 efs defaults,_netdev 0 0" >> /etc/fstab

cd /mnt/efs/fs1
if [ ! -d save ] ; then
  mkdir save
  chgrp wheel save
  chmod 777 save
  ln -s /mnt/efs/fs1/save /save
fi


## git clone the Cloud-Sandbox repository
#########################################

cd /mnt/efs/fs1/save
mkdir $RUNUSER
chown $RUNUSER:$RUNUSER $RUNUSER
cd $RUNUSER
sudo -u $RUNUSER git clone https://github.com/ioos/Cloud-Sandbox.git
cd Cloud-Sandbox
sudo -u $RUNUSER git checkout $BRANCH
cd scripts

# Need to pass ami_name for image creation
# ami_name is defined in main.tf user_data
export ami_name=${ami_name}
echo "ami name : $ami_name"

## Install all of the software and drivers
##########################################
# sudo -E -u $RUNUSER ./setup-instance.sh >> ~/setup.log 2>&1

# TODO: Check for errors returned from any step above

echo "Installation completed!" >> ~/setup.log
echo `date` >> ~/setup.log
