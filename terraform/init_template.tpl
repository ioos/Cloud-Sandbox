#!/usr/bin/env bash

mkdir -p /mnt/efs
yum -y -q install git amazon-efs-utils
echo "${efs_name}:/ /mnt/efs nfs defaults,_netdev 0 0" >> /tmp/debug_efs.txt
mount -t nfs4 "${efs_name}:/" /mnt/efs
echo "${efs_name}:/ /mnt/efs nfs defaults,_netdev 0 0" >> /etc/fstab

cd /home/centos
sudo -u centos git clone https://github.com/asascience/Cloud-Sandbox.git
cd Cloud-Sandbox/cloudflow/workflows/scripts
sudo -u centos ./nosofs-setup-instance.sh > /tmp/setup 2>&1
