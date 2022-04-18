#!/usr/bin/env bash

mkdir -p /mnt/efs/fs1
yum -y -q install git amazon-efs-utils

echo "${efs_name}:/ /mnt/efs/fs1 nfs defaults,_netdev 0 0" >> /tmp/debug_efs.txt
mount -t nfs4 "${efs_name}:/" /mnt/efs/fs1
echo "${efs_name}:/ /mnt/efs/fs1 nfs defaults,_netdev 0 0" >> /etc/fstab

cd /home/centos
sudo -u centos git clone https://github.com/ioos/Cloud-Sandbox.git
cd Cloud-Sandbox/cloudflow/workflows/scripts

sudo -u centos ./setup-instance.sh > /tmp/setup.log 2>&1

# MPI needs key to ssh into cluster nodes
sudo -u centos ssh-keygen -t rsa -N ""  -C "mpi-ssh-key" -f /home/centos/.ssh/id_rsa
sudo -u centos cat /home/centos/.ssh/id_rsa.pub >> /home/centos/.ssh/authorized_keys

cat >> /etc/ssh/ssh_config <<EOL

Host ip-10-0-* 
   CheckHostIP no 
   StrictHostKeyChecking no 

Host 10.0.* 
   CheckHostIP no 
   StrictHostKeyChecking no
EOL

# Create the AMI from this instance
instance_id=`curl http://169.254.169.254/latest/meta-data/instance-id`

echo "Current instance is: $instance_id" >> /tmp/setup.log 
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-resize.html
#instance ID does not change if able to change instance type without destroying the old one

echo "Creating an AMI of this instance ... will reboot automatically" >> /tmp/setup.log 
/usr/local/bin/aws --region ${aws_region} ec2 create-image --instance-id $instance_id --name "${ami_name}" \
  --tag-specification "ResourceType=image,Tags=[{Key=\"Name\",Value=\"${ami_name}\"},{Key=\"Project\",Value=\"${project}\"}]" > /tmp/ami.log 2>&1

# TODO: Check for errors returned from any step above

imageID=`grep ImageId /tmp/ami.log`
echo "imageID to use for compute nodes is: $imageID" >> /tmp/setup.log 
echo "Installation completed!" >> /tmp/setup.log
