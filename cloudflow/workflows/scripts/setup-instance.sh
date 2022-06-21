#!/usr/bin/env bash

#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

# source include the functions 
. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo
sudo setenforce 0

# Use caution when changing the order of the following

# System stuff
setup_environment
setup_paths
setup_aliases
# setup_ssh_mpi
# install_efa_driver

# Compilers and libraries
install_python_modules_user
# install_spack
# install_gcc
# install_intel_oneapi
# install_netcdf
#install_hdf5-gcc8   # Not needed?
# install_esmf
# install_base_rpms
# install_extra_rpms
# install_ffmpeg

# Job scheduler, resource manager
# install_munge

# Compute node config
# install_slurm-epel7 compute
# sudo yum -y clean all

# Take a snapshot for compute nodes
snapshotId=`create_snapshot "Compute Node"`

# Create AMI for compute nodes

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default
# TODO: make sure imageName is unique

echo "$0 ami_name: $ami_name"
printenv
imageName="${ami_name:=IOOS cloud sandbox} Compute Node"
echo "$0 imageName: $imageName"

imageId=`python3 create_image.py $snapshotId "$imageName"`
echo "Compute node image: $imageId"

# Head node 
# install_slurm-epel7 head
# sudo yum -y clean all

# create snapshot for potential re-use
# snapshotId=`create_snapshot "Head Node"`
# echo "Snapshot taken: $snapshotId"

# imageName="${ami_name:='IOOS cloud sandbox'} Head Node"
# imageId=`python3 create_image.py $snapshotId "$imageName"`

# echo "Setup completed!"
