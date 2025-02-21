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

# SPACK_CACHEONLY=0

##########################################################

# Need to upgrade spack version. 0.22.3 is non-breaking
# save current location first
home=$PWD
cd $SPACK_DIR
git checkout $SPACK_VER
cd $home

# source include the functions 
. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo command
sudo setenforce 0

install_efa_driver

source /opt/rh/gcc-toolset-11/enable

spack load intel-oneapi-compilers@2023.1.0

# netcdf, hdf5, and other dependencies will be installed with ESMF
install_esmf_spack

# Create symbolic links to netcdf libraries
# Some makefiles expect netcdfc and netcdff to be in same folder
# 
NC_FORTRAN=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-fortran-4.6.1-cpxxwcig5kifogteqpenkxw35q6tthgt/lib
NC_C=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vkckbzk37srvezgw4yt7existfejyque/lib

if [ -d $NC_FORTRAN ] && [ -d $NC_C ]; then
    cd $NC_C
    ln -s $NC_FORTRAN/libnetcdff* .

    #cp -p \
        #/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-fortran-4.6.1-cpxxwcig5kifogteqpenkxw35q6tthgt/lib/libnetcdff* \
        #/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vkckbzk37srvezgw4yt7existfejyque/lib/
else
    echo "WARNING: Could not create symbolic links for netcdf libraries"
fi

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# !! ami_names must be unique - unique name is provided during initial deployment
#------------------------------------------------------------------------------
ami_name=nos-cloud-sandbox_mpi-${INTEL_MPI_VER}
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# create node image
###################################

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default
ami_name=${ami_name:='IOOS-Cloud-Sandbox'}

# TODO: pass this in via Terraform init template
project_tag=${project_tag:="IOOS-Cloud-Sandbox"}

# create node image
###################################

echo "Creating new image for compute nodes.\nThe old image might still work,\nif not, use this new image in your cluster configs."

./create_image.sh $ami_name $project_tag

echo "Upgrade completed!"
