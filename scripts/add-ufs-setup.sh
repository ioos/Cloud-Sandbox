#!/usr/bin/env bash

#__copyright__ = "Copyright © 2026 Tetra Tech, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

source ufs-envars.sh

###############################################################
# Note: before adding spack-stack, unset the current spack !!!
#
# Edit ~/.bashrc and remove the following line:
# . /save/environments/spack.v0.22.5/share/spack/setup-env.sh
#
# Edit ~/.tcshrc and remove the following line:
# source /save/environments/spack.v0.22.5/share/spack/setup-env.csh
#
# close your existing shells and open a new one
###############################################################

# source include the functions 
. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo command
sudo setenforce 0

# Compilers and libraries
install_gcc_toolset_yum
install_intel_oneapi_dnf

# Spack-stack
install_spack-stack_prereqs

setup_spack-stack 
build_spack-environment

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
