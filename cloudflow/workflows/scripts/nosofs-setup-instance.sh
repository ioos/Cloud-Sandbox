#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

. base-setup-instance.sh

# calling sudo from cloud init adds 25 second delay for each sudo
sudo setenforce 0

setup_environment
setup_paths
install_efa_driver
install_impi
install_base_rpms
install_extra_rpms
install_python_modules_user
install_ffmpeg
setup_aliases

echo "Setup completed!"
