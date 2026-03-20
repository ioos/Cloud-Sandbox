#!/usr/bin/env bash

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

source ufs-envars.sh

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

#install_efa_driver
#install_fsx_driver

# Compilers and libraries
# install_gcc_toolset_yum

# install_intel_oneapi_dnf
# install_spack-stack_prereqs
setup_spack-stack 
build_spack-environment

echo "done"; exit

install_python_modules_user
setup_ssh_mpi

# install_petsc_intelmpi-spack

# TODO: create an output file to contain all of this state info - json

# create node image
###################################

spack clean -a
sudo yum clean all

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default
now=`date -u +\%Y\%m\%d_\%H-\%M`
ami_name=${ami_name:="IOOS-Cloud-Sandbox-${now}"}
echo "ami_name: $ami_name"

# TODO: pass this in via Terraform init template
project_tag=${project_tag:="IOOS-Cloud-Sandbox"}

# create node image
###################################

./create_image.sh $ami_name $project_tag

echo "Setup completed!"
