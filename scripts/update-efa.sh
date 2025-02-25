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

# create node image
###################################

./create_image.sh $ami_name $project_tag

echo "Setup completed!"
