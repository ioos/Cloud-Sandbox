#!/usr/bin/env bash

# This is a file to update an existing sandbox deployment
# in order to run CORA ADCIRC 

# Uninstall the existing netcdf-fortran and reinstall using updated mirror

sudo yum -y install bc
spack uninstall -y --dependents netcdf-fortran@4.6.1

# Rebuild mirror 

SPACK_DIR='/save/environments/spack'
SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'
SPACK_KEY_URL='https://ioos-cloud-sandbox.s3.amazonaws.com/public/spack/mirror/spack.mirror.gpgkey.pub'

spack buildcache --rebuild-index  $SPACK_MIRROR    # Full sync with build cache
# spack buildcache --update-index   $SPACK_MIRROR  # use only when adding NEW items

./reinstall-esmf-netcdf.sh

#create symbolic links to fortran libraries in fortran-c folder
# adcirc make expects them to be in same folder - can fix that later
cd /save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vznmeikm7cp5ht2ktorgf2ehhzgvqqel/lib || exit 1

ln -s ../../netcdf-fortran-4.6.1-meeveojv5q6onmj6kitfb2mwfqscavn6/lib/lib* .

cd /save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vznmeikm7cp5ht2ktorgf2ehhzgvqqel/include || exit 1

ln -s ../../netcdf-fortran-4.6.1-meeveojv5q6onmj6kitfb2mwfqscavn6/include/* .
