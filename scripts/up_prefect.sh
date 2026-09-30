#!/usr/bin/env bash

#__copyright__ = "Copyright © 2026 Tetra Tech, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

source environment-vars.sh

##########################################################

# source include the functions 
. funcs-setup-instance.sh

# Setup Prefect as a system daemon
setup_prefect-server

echo "Setup completed!"
