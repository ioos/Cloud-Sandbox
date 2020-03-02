#!/bin/bash
#yum update -y
yum install -y nfs-utils
FILE_SYSTEM_ID=fs-cc5fd34d
AVAILABILITY_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone )
REGION=${AVAILABILITY_ZONE:0:-1}
MOUNT_POINT=/mnt/efs
mkdir -p ${MOUNT_POINT}
chown centos:centos ${MOUNT_POINT}
echo ${FILE_SYSTEM_ID}.efs.${REGION}.amazonaws.com:/ ${MOUNT_POINT} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=60,retrans=2,_netdev 0 0 >> /etc/fstab
mount -a -t nfs4 --verbose

