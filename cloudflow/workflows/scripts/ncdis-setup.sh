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
setup_aliases
#setup_ssh_mpi
#install_efa_driver

# Compilers and libraries
install_spack
install_gcc
install_intel_oneapi
install_netcdf

# Install jupyterhub
./install_jupyterhub.sh

sudo yum -y clean all

echo "Setup completed!"
