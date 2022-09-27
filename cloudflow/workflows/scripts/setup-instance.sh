#!/usr/bin/env bash

#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

# source include the functions 
. funcs-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo
sudo setenforce 0

# Use caution when changing the order of the following

# System stuff
setup_environment
setup_paths
setup_aliases
setup_ssh_mpi
install_efa_driver

# Compilers and libraries
install_python_modules_user
install_spack
install_gcc
install_intel_oneapi
install_esmf
install_base_rpms
install_extra_rpms
install_ffmpeg


# Compute node config
install_slurm

configure_slurm compute
sudo yum -y clean all

# TODO: create an output file to contain all of this state info - json
# TODO: re-write in Python ?

## Create the AMI to be used for the compute nodes
# TODO: make the next section cleaner, more abstracted away

export AWS_DEFAULT_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/[a-z]$//')
instance_id=`curl -s http://169.254.169.254/latest/meta-data/instance-id`

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default

ami_name=${ami_name:='IOOS-Cloud-Sandbox'}

# TODO: pass this in via Terraform init template
project_tag="IOOS-Cloud-Sandbox"

image_name="${ami_name}-Compute-Node"
echo "Compute node image_name: '$image_name'"

# For some reason these aren't being seen 
# Try installing them again in this shell
python3 -m pip install --user --upgrade botocore==1.23.46
python3 -m pip install --user --upgrade boto3==1.20.46

# Flush the disk cache
sudo sync

image_id=`python3 create_image.py $instance_id "$image_name" "$project_tag"`
echo "Compute node image_id: $image_id"

# Configure this machine as a head node
configure_slurm head
sudo yum -y clean all

# Optionally create Head node image
###################################

image_name="${ami_name}-Head-Node"
echo "Head node image_name: $image_name"

sudo sync
image_id=`python3 create_image.py $instance_id "$image_name" "$project_tag"`
echo "Head node image_id: $image_id"

echo "Setup completed!"
