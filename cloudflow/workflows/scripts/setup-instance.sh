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

# This is extremely slow to build
# TODO:DOING: create a spack build cache on S3 and use that for thes installations
install_spack
install_gcc
install_intel_oneapi
install_netcdf

install_extra_rpms
install_ffmpeg

sudo yum -y clean all

echo "Setup completed!"
