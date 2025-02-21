#!/usr/bin/env bash

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

GCC_VER=11.2.1

# Current used versions
ONEAPI_VER=2023.1.0
# The ONEAPI_VER above ^^^^ installs the INTEL_COMPILER_VERSION below vvvv
INTEL_COMPILER_VER=2021.9.0

# Upgrading INTEL_MPI for 2 EFA adaptors support, version 2021.12.0+
# MPI v 2021.12.0+ supports multiple EFA adaptors
# spack v0.22.3 and higher has that spec
# problems with spack v23
INTEL_MPI_VER=2021.12.1

ESMF_VER=8.5.0

SPACK_VER='v0.22.3'
SPACK_DIR='/save/environments/spack'
SPACKOPTS='-v -y'

#SPACKTARGET='target=skylake_avx512'        # default on skylake intel instances t3.xxxx
#export SPACKTARGET='target=haswell'        # works on AMD also - has no avx512 extensions
#SPACKTARGET='target=x86_64'                 # works on anything
SPACKTARGET="arch=linux-rhel8-x86_64"

#EFA_INSTALLER_VER='1.32.0'
EFA_INSTALLER_VER='1.38.0'

#  1 = Don't build any packages. Only install packages from binary mirrors
#  0 = Will build if not found in mirror/cache
# -1 = Don't check pre-built binary cache
SPACK_CACHEONLY=1

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

## install_jupyterhub # Requires some manual work
setup_ssh_mpi
install_efa_driver

# Compilers and libraries
install_python_modules_user
install_gcc_toolset_yum

source /opt/rh/gcc-toolset-11/enable

install_spack
install_intel_oneapi_spack
install_esmf_spack   # also installs netcdf, hdf5, intel-mpi

install_base_rpms
install_ncep_rpms

# install_ffmpeg

# TODO: create an output file to contain all of this state info - json

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
