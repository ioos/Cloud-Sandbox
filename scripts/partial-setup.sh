#!/usr/bin/env bash

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

source environment-vars.sh

##########################################################

# source include the functions 
. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo command
sudo setenforce 0

# Use caution when changing the order of the following

# System stuff
# setup_paths
# setup_aliases
# setup_environment

## install_jupyterhub # Requires some manual work
# setup_ssh_mpi
# install_efa_driver
# install_fsx_driver

# Compilers and libraries
# install_python_modules_user
# install_gcc_toolset_yum

source /opt/rh/gcc-toolset-11/enable

# install_spack
# install_intel_oneapi_spack
# install_esmf_spack   # also installs netcdf, hdf5, intel-mpi

# TODO: Install these libraries via spack
#install_base_rpms
#install_ncep_rpms

install_petsc_intelmpi-spack

# install_ffmpeg

# TODO: create an output file to contain all of this state info - json

# create node image
###################################

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default
now=`date -u +\%Y\%m\%d_\%H-\%M`
ami_name=${ami_name:="IOOS-Cloud-Sandbox-${now}"}
echo "ami_name: $ami_name"

# TODO: pass this in via Terraform init template
project_tag=${project_tag:="IOOS-Cloud-Sandbox"}

# create node image
###################################

# ./create_image.sh $ami_name $project_tag

echo "Setup completed!"
