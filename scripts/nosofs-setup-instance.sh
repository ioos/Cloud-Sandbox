#!/bin/bash

. base-setup-instance.sh

setup_environment
install_efa_driver
install_base_rpms
install_extra_rpms
install_impi
install_ffmpeg
install_python_modules_user

