#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo
sudo setenforce 0

# DO NOT CHANGE THE ORDER!
setup_environment
setup_paths
setup_aliases
install_efa_driver
install_python_modules_user

install_spack
install_gcc
install_intel_oneapi
install_netcdf
#install_hdf5-gcc8

install_munge
exit

install_slurm

install_esmf
install_base_rpms
install_extra_rpms
install_ffmpeg

sudo yum -y clean all

echo "Setup completed!"
