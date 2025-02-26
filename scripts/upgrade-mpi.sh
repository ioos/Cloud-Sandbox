#!/usr/bin/env bash

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

source environment-vars.sh

##########################################################

home=$PWD

# calling sudo from cloud init adds 25 second delay for each sudo command
sudo setenforce 0

# source include the functions 
. funcs-setup-instance.sh



install_efa_driver

source /opt/rh/gcc-toolset-11/enable

# Upgrade spack version.
cd $SPACK_DIR
git fetch --tags
git checkout $SPACK_VER
cd $home

. $SPACK_DIR/share/spack/setup-env.sh
spack mirror add s3-mirror $SPACK_MIRROR

spack buildcache keys --install --trust --force
spack buildcache update-index $SPACK_MIRROR

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
# THIS IS HARDCODED for the current version - UPDATE if needed
#####################################################################
NC_FORTRAN=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-fortran-4.6.1-cpxxwcig5kifogteqpenkxw35q6tthgt/lib
NC_C=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vkckbzk37srvezgw4yt7existfejyque/lib

if [ -d $NC_FORTRAN ] && [ -d $NC_C ]; then
    cd $NC_C
    ln -s $NC_FORTRAN/libnetcdff* .
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
