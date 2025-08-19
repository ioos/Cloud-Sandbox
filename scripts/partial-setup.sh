#!/usr/bin/env bash
#set -x

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

source environment-vars.sh

##########################################################

# source include the functions 
source funcs-setup-instance.sh

# Use caution when changing the order of the following

# System stuff
# setup_paths
set -x
setup_aliases
exit
# setup_environment

## install_jupyterhub # Requires some manual work
# setup_ssh_mpi
# install_efa_driver
# install_fsx_driver

# Compilers and libraries
# install_python_modules_user
# install_gcc_toolset_yum
# source /opt/rh/gcc-toolset-11/enable
# gcc --version

#remove_spack
#install_spack

#install_intel_oneapi_spack

# Skipping mkl for now
# install_intel-oneapi-mkl_spack

#install_esmf_spack          # also installs netcdf, hdf5, intel-mpi
#install_petsc_intelmpi-spack

# TODO: Install these libraries via spack
#install_base_rpms
#install_ncep_rpms

# install_ffmpeg

# TODO: create an output file to contain all of this state info - json

spack clean

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

./create_image.sh $ami_name $project_tag

echo "Setup completed!"
