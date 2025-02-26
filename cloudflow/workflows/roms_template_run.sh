#!/bin/bash
# redirect stdout/stderr to a file
#exec &> /save/ec2-user/OWP/laura/schism_cloud_sandbox_log.txt

set -e       # exit immediately on error
set -x       # verbose with command expansion
set -u       # forces exit on undefined variables

module purge
module use -a /mnt/efs/fs1/save/environments/spack/share/spack/modules/linux-rhel8-x86_64

module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3a7dxu3
module load intel-oneapi-mpi/2021.9.0-intel-2021.9.0-egjrbfg
module load netcdf-c/4.9.2-intel-2021.9.0-vznmeik
module load netcdf-fortran/4.6.1-intel-2021.9.0-meeveoj
module load parallelio/2.6.2-intel-2021.9.0-csz55zr

export FC=mpiifort
export CXX=mpiicpc
export CC=mpiicc

export LD_LIBRARY_PATH=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-fortran-4.6.1-meeveojv5q6onmj6kitfb2mwfqscavn6/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vznmeikm7cp5ht2ktorgf2ehhzgvqqel/lib:$LD_LIBRARY_PATH

export MODEL_DIR=$1
export IN_FILE=$2
export EXEC=$3

echo "---" 
echo "------------------------"
echo "ROMS model working directory is $MODEL_DIR"
echo "------------------------"
cd $MODEL_DIR

SECONDS=0

# Since Cloud-Sandbox can only currently compile
# ROMS with OPENMP capabilites only, we will go
# ahead here and export the number of threads
# for OPENMP code based on what the user configured
# for AWS cloud resources
export OMP_NUM_THREAD=$NPROCS

echo "--- " 
echo "--- Running ROMS -----------------"
echo "---"

mpirun $MPIOPTS $EXEC < $IN_FILE


if [ $? -ne 0 ]; then
  echo "ERROR returned from mpirun"
else
  echo "ROMS model has succesfully completed on the cloud!"
  duration=$SECONDS
  echo "ROMS simulation took $((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
fi
