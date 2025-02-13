#!/bin/bash

# Required in order for your
# script to properly exit if an
# error is thrown within the shell
# script or model execution so the
# AWS cluster can properly shutdown
set -e       # exit immediately on error
set -x       # verbose with command expansion
set -u       # forces exit on undefined variables


module purge
module use -a /mnt/efs/fs1/save/environments/spack/share/spack/modules/linux-rhel8-x86_64

# User needs to load up the defined compilers and libraries
# they used for compiling their model within this block here
module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3a7dxu3
module load intel-oneapi-mpi/2021.9.0-intel-2021.9.0-egjrbfg
module load netcdf-c/4.9.2-intel-2021.9.0-vznmeik
module load netcdf-fortran/4.6.1-intel-2021.9.0-meeveoj
module load parallelio/2.6.2-intel-2021.9.0-csz55zr

# Export required variables
# for your model executable
# if required
export FC=mpiifort
export CXX=mpiicpc
export CC=mpiicc

# This is where you define your 
# shell script required inputs
# to execute your model run
export MODEL_DIR=$1
export EXEC=$2


echo "---" 
echo "------------------------"
echo "Model XXX working directory is $MODEL_DIR"
echo "------------------------"
cd $MODEL_DIR

SECONDS=0
echo "--- " 
echo "--- Running MODEL XXXX -----------------"
echo "---"

##### Example model executable syntax required
#mpiexec $MPIOPTS $EXEC
result=$?

# Capture the exit/end result and propagate it down the stack.
if [ $result -ne 0 ]; then
  echo "ERROR returned from mpirun"
  exit $result
else
  echo "XXX model has succesfully completed on the cloud!"
  duration=$SECONDS
  echo "XXX model simulation took $((duration / 60)) minutes and $((duration % 60)) seconds to complete."
fi
