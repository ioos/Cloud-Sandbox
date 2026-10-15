#!/usr/bin/env bash

#__copyright__ = "Copyright © 2026 Tetra Tech, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

source environment-vars.sh

##########################################################

# source include the functions 
. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo command
sudo setenforce 0

# Use caution when changing the order of the following

# System stuff
#setup_paths
#setup_aliases
#setup_environment

# Setup Prefect as a system daemon
#setup_prefect-server

#setup_ssh_mpi

install_efa_driver

exit

#install_fsx_driver

#install_python_modules_user

# Install compilers, mkl, and mpi, etc.
# install_intel_oneapi_dnf

if [[ "$USE_SPACK_STACK" == "YES" ]]; then
  echo "Using the ufs spack-stack instead of spack"

#  install_spack-stack_prereqs

  # install_gcc_toolset_dnf

  # Install Intel Compiler outside of spack-stack environment
  source /opt/intel/oneapi/setvars.sh
  if [ $? -ne 0 ]; then
      echo "WARNING: Intel oneApi Compilers not found!"
  fi

#  module use -a /save/environments/modulefiles
#
#  module load intel/compiler/2024.2.1
#  module load intel/compiler-intel-llvm/2024.2.1
#  module load intel/ifort/2024.2.1
#  module load intel/mpi/2021.16
#  module load intel/mkl/2024.2

#  setup_modulefiles_lua

#  setup_spack-stack

#  echo "Building spack-stack environment ... please wait"
#  build_spack-stack-environment

else

  echo "Not using spack-stack "

  setup_modulefiles_tcl

  module --version

  install_spack

  . $SPACK_DIR/share/spack/setup-env.sh

  create_spack-environment

  build_spack-environment
fi

# configure_optimizations

# create node image
###################################

spack clean --all
sudo dnf clean all

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default
now=`date -u +\%Y\%m\%d_\%H-\%M`
ami_name=${ami_name:="IOOS-Cloud-Sandbox-${now}"}
echo "ami_name: $ami_name"

# TODO: pass this in via Terraform init template
project_tag=${project_tag:="IOOS-Cloud-Sandbox"}

# create node image
###################################

## disable prefect server daemon
sudo systemctl stop prefect-server
sudo systemctl disable prefect-server

./create_image.sh $ami_name $project_tag

## re-enable prefect server daemon
sudo systemctl enable prefect-server
sudo systemctl start prefect-server

sudo setenforce 1

echo "Setup completed!"
