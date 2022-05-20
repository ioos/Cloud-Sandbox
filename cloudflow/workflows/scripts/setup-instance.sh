#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

nodetype=head

. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo
sudo setenforce 0

# Use caution when changing the order of the following
setup_environment
setup_paths
setup_aliases
install_efa_driver
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

install_munge
install_slurm-epel7 compute

# Take a snapshot
create_snapshot

# Create AMI for compute nodes
# output and save the image id

install_slurm-epel7 head
create snapshot

sudo yum -y clean all

echo "Setup completed!"
