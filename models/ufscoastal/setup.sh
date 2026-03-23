#!/usr/bin/env bash

# https://ufs-coastal-application.readthedocs.io/en/latest/index.html


# module use -a /save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8/modules

cd /save/$USER
git clone --recursive https://github.com/asascience-open/ufs-weather-model.git

cd ufs-weather-model
# Example from readthedocs: 
module use -a modulefiles
#module load ufs_hercules.intel

#Core/stack-intel-oneapi-compilers/2024.2.1 
#impi/2021.13.0/none/none/ufs-srw-app-env/1.0.0 
#impi/2021.13.0/none/none/ufs-weather-model-env/1.0.0 
