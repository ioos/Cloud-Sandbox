#!/usr/bin/env bash

echo `date` > /tmp/setup.log

mkdir -p /mnt/efs/fs1
yum -y -q install git amazon-efs-utils

mount -t nfs4 "${efs_name}:/" /mnt/efs/fs1
echo "${efs_name}:/ /mnt/efs/fs1 nfs defaults,_netdev 0 0" >> /etc/fstab

cd /home/centos
sudo -u centos git clone https://github.com/ioos/Cloud-Sandbox.git
cd Cloud-Sandbox/cloudflow/workflows/scripts

#BRANCH=master
BRANCH=slurm-install

sudo -u centos git checkout $BRANCH

# Need to pass ami_name
export ami_name=${ami_name}

sudo -E -u centos ./setup-instance.sh >> /tmp/setup.log 2>&1

# TODO: Check for errors returned from any step above

echo "Installation completed!" >> /tmp/setup.log
echo `date` >> /tmp/setup.log
