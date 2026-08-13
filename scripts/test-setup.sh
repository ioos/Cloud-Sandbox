#!/usr/bin/env bash

#__copyright__ = "Copyright © 2026 Tetra Tech, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

source environment-vars.sh

##########################################################

# source include the functions 
. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo command
sudo setenforce 0

# Use caution when changing the order of the following

# System stuff
#setup_paths
#setup_aliases
#setup_environment

# Setup Prefect as a system daemon
#setup_prefect-server

# install_jupyterhub # Requires some manual work
#setup_ssh_mpi

#install_efa_driver
#install_fsx_driver

# Compilers and libraries
#install_python_modules_user

#install_spack

. $SPACK_DIR/share/spack/setup-env.sh

# Install compilers, mkl, and mpi, etc.

#install_intel_oneapi_dnf

# create_spack-environment

build_spack-environment

exit 0

#configure_optimizations

# create node image
###################################

spack clean --all
sudo dnf clean all

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default
now=`date -u +\%Y\%m\%d_\%H-\%M`
ami_name=${ami_name:="IOOS-Cloud-Sandbox-${now}"}
echo "ami_name: $ami_name"

# TODO: pass this in via Terraform init template
project_tag=${project_tag:="IOOS-Cloud-Sandbox"}

# create node image
###################################

## disable prefect server daemon
sudo systemctl stop prefect-server
sudo systemctl disable prefect-server

./create_image.sh $ami_name $project_tag

## re-enable prefect server daemon
sudo systemctl enable prefect-server
sudo systemctl start prefect-server

sudo setenforce 1

echo "Setup completed!"
