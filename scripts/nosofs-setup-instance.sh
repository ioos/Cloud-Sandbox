#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

. base-setup-instance.sh

setup_environment
install_efa_driver
install_base_rpms
install_extra_rpms
install_impi
install_ffmpeg
install_python_modules_user

