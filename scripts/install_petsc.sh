#!/usr/bin/env bash

#set -x
#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

source environment-vars.sh

##########################################################

# source include the functions 
. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo command
sudo setenforce 0

# Use caution when changing the order of the following

# System stuff
source /opt/rh/gcc-toolset-11/enable

#spack load intel-oneapi-compilers@2023.1.0
#spack load intel-oneapi-mpi@2021.12.1
#spack load esmf@8.5.0

install_intel_oneapi_spack
#install_petsc_intelmpi-spack


# also needed for FVCOM
# sudo yum install byacc
# git clone makedepf90
# make it and make install -t


# create node image
###################################

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default or what is provided in environment-vars.sh
ami_name=${ami_name:='IOOS-Cloud-Sandbox'}

# TODO: pass this in via Terraform init template
project_tag=${project_tag:="IOOS-Cloud-Sandbox"}

# create node image
###################################

# TESTING
# ./create_image.sh $ami_name $project_tag

echo "Setup completed!"
