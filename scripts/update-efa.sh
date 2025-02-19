#!/usr/bin/env bash

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

GCC_VER=11.2.1

# Current versions
ONEAPI_VER=2023.1.0

# Note: There is no oneapi mpi version 2023.1.0
INTEL_COMPILER_VER=2021.9.0
INTEL_MPI_VER=2021.14.1

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
SPACK_CACHEONLY=1

##########################################################

# source include the functions 
. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo command
sudo setenforce 0

# Use caution when changing the order of the following

module use -a /save/environments/modulefiles

# install_efa_driver

# source /opt/rh/gcc-toolset-11/enable

# create node image
###################################

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default
ami_name=${ami_name:='2025-02-13-0751-IOOS-Cloud-Sandbox'}

# TODO: pass this in via Terraform init template
project_tag=${project_tag:="IOOS-Cloud-Sandbox"}

# create node image
###################################

./create_image.sh $ami_name $project_tag

echo "Setup completed!"
