#!/usr/bin/env bash

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

GCC_VER=11.2.1

# Current versions
ONEAPI_VER=2023.1.0

# There is no oneapi mpi version 2023.1.0
INTEL_VER=2021.9.0
# MPI_VER=2021.9.0
ESMF_VER=8.5.0

#SPACK_VER='releases/v0.18'
#SPACK_DIR='/save/environments/spack-stack/spack'

SPACK_VER='v0.21.0'
SPACK_DIR='/save/environments/spack'

SPACKOPTS='-v -y'

#SPACKTARGET='target=skylake_avx512'        # default on skylake intel instances t3.xxxx
#export SPACKTARGET='target=haswell'        # works on AMD also - has no avx512 extensions
#SPACKTARGET='target=x86_64'                 # works on anything
SPACKTARGET="arch=linux-rhel8-x86_64"

#  1 = Don't build any packages. Only install packages from binary mirrors
#  0 = Will build if not found in mirror/cache
# -1 = Don't check pre-built binary cache
SPACK_CACHEONLY=0

##########################################################

# source include the functions 
. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo command
sudo setenforce 0

# Use caution when changing the order of the following

# System stuff
setup_paths
setup_aliases
setup_environment

module use -a /save/environments/modulefiles

## install_jupyterhub # Requires some manual work
setup_ssh_mpi
install_efa_driver

# Compilers and libraries
install_python_modules_user
install_gcc_toolset_yum

source /opt/rh/gcc-toolset-11/enable

install_spack
install_intel_oneapi_spack
install_esmf_spack

install_base_rpms
install_ncep_rpms

# install_ffmpeg

# TODO: create an output file to contain all of this state info - json
# TODO: re-write in Python ?

# create node image
###################################

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default
ami_name=${ami_name:='IOOS-Cloud-Sandbox'}

# TODO: pass this in via Terraform init template
project_tag=${project_tag:="IOOS-Cloud-Sandbox"}

# create node image
###################################

./create_image.sh $ami_name $project_tag

echo "Setup completed!"
