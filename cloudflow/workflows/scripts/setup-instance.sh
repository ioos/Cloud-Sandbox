#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

nodetype=head

. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo
sudo setenforce 0

# Use caution when changing the order of the following

# System stuff
setup_environment
setup_paths
setup_aliases
setup_ssh_mpi
install_efa_driver

# Compilers and libraries
install_python_modules_user
install_spack
install_gcc
install_intel_oneapi
install_netcdf
#install_hdf5-gcc8
install_esmf
install_base_rpms
install_extra_rpms
install_ffmpeg

# Job scheduler, resource manager
install_munge

# Compute node config
install_slurm-epel7 compute
sudo yum -y clean all

# Take a snapshot for compute node
snapshotId=`create_snapshot "Compute Node"`
echo "Snapshot taken: $snapshotId"

# Create AMI for compute nodes
# output and save the image id

# Head node 
install_slurm-epel7 head
sudo yum -y clean all

# create snapshot for potential re-use
snapshotId=`create_snapshot "Head Node"`
echo "Snapshot taken: $snapshotId"

echo "Setup completed!"
