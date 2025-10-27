#!/usr/bin/env bash

#__copyright__ = "Copyright © 2025 Tetra Tech, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

GCC_VER=11.2.1

# Current versions
ONEAPI_VER=2023.1.0

# There is no oneapi mpi version 2023.1.0
INTEL_VER=2021.9.0
# MPI_VER=2021.9.0
ESMF_VER=8.5.0

SPACK_VER='v0.21.0'
SPACK_DIR='/save/environments/spack'

SPACKOPTS='-v -y'

SPACKTARGET="arch=linux-rhel8-x86_64"

#  1 = Don't build any packages. Only install packages from binary mirrors
#  0 = Will build if not found in mirror/cache
# -1 = Don't check pre-built binary cache
SPACK_CACHEONLY=1
#SPACK_CACHEONLY=-1

##########################################################

# source include the functions 
source ../../scripts/funcs-setup-instance.sh

module use -a /save/environments/modulefiles
source /opt/rh/gcc-toolset-11/enable

install_esmf_spack

echo "Setup completed!"
