#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo
sudo setenforce 0

setup_environment
setup_paths
setup_aliases
install_efa_driver
install_python_modules_user
install_spack
install_gcc
install_intel_oneapi
install_netcdf
install_esmf
install_base_rpms
install_extra_rpms
install_ffmpeg

#  spack mirror add s3-mirror s3://ioos-cloud-sandbox/public/spack/mirror
#  spack buildcache update-index -d s3://ioos-cloud-sandbox/public/spack/mirror/

sudo yum -y clean all

echo "Setup completed!"
