#!/usr/bin/env bash

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

##########################################################

echo "WARNING: this will completely remove the current spack environment."
echo "Are you sure you want to continue? (y/n)"
read -p "Your choice: " choice

if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo "continuing with installation ..."
else
    echo "installation cancelled."
    exit 1
fi

##########################################################

source environment-vars.sh

home=$PWD

# calling sudo from cloud init adds 25 second delay for each sudo command
sudo setenforce 0

# source include the functions
. funcs-setup-instance.sh

remove_spack

install_efa_driver

source /opt/rh/gcc-toolset-11/enable

install_spack

install_intel_oneapi_spack




spack load intel-oneapi-compilers@2023.1.0

# netcdf, hdf5, and other dependencies will be installed with ESMF

install_esmf_spack
retval=$?
if [ $retval -ne 0 ]; then
  echo "ERROR: install_esmf_spack() failed."
  exit $retval
fi

#####################################################################
# Create symbolic links to netcdf libraries
# Some makefiles expect netcdfc and netcdff to be in same folder
# NC_FORTRAN and NC_C ARE HARDCODED for the current version - UPDATE if needed
# 
# TODO: maybe use spack location, but will break if more than one is installed with different hashes/dependencies
# spack location -i gcc@$GCC_VER
# spack location -i intel-oneapi-compilers \%${GCC_COMPILER}`/compiler/latest/linux/bin/intel64
# nctest=`spack location -i netcdf-fortran \%intel\@${INTEL_COMPILER_VER}`
#
# THIS IS HARDCODED for the current version - UPDATE if needed - so far only needed by adcirc cmake build
#####################################################################

NC_FORTRAN=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-fortran-4.6.1-cpxxwcig5kifogteqpenkxw35q6tthgt
NC_C=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vkckbzk37srvezgw4yt7existfejyque

if [ -d $NC_FORTRAN ] && [ -d $NC_C ]; then
    ln -s $NC_FORTRAN/lib/libnetcdff* $NC_C/lib >& /dev/null
    ln -s $NC_FORTRAN/include/* $NC_C/include >& /dev/null
    cd $home
else
    echo "WARNING: Could not create symbolic links for netcdf libraries"
fi

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# !! ami_names must be unique 
#    environment_vars provides name using current date time
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# create node image
###################################

echo "Creating new image for compute nodes."
echo "Use this new image in your cluster configs."

./create_image.sh $ami_name $project_tag

echo "Upgrade completed!"
