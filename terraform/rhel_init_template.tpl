#!/usr/bin/env bash

echo `date` > /tmp/setup.log

USER="ec2-user"

#USER="centos"

mkdir -p /mnt/efs/fs1

sudo yum -y install git
sudo yum -y install rpm-build
sudo yum -y install make
git clone https://github.com/aws/efs-utils
cd efs-utils/
sudo make rpm
sudo yum -y install ./build/amazon-efs-utils*rpm

mount -t nfs4 "${efs_name}:/" /mnt/efs/fs1
echo "${efs_name}:/ /mnt/efs/fs1 nfs defaults,_netdev 0 0" >> /etc/fstab

cd /home/$USER
sudo -u $USER git clone https://github.com/ioos/Cloud-Sandbox.git
cd Cloud-Sandbox/cloudflow/workflows/scripts

BRANCH=ufs-apps
#BRANCH=master

sudo -u $USER git checkout $BRANCH

# Need to pass ami_name
export ami_name=${ami_name}

sudo -E -u $USER ./setup-instance.sh >> /tmp/setup.log 2>&1

# TODO: Check for errors returned from any step above

echo "Installation completed!" >> /tmp/setup.log
echo `date` >> /tmp/setup.log
