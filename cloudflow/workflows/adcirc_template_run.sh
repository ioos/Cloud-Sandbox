#!/bin/bash

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

export MODEL_DIR=$1
export EXEC=$2


echo "---" 
echo "------------------------"
echo "ADCIRC model working directory is $MODEL_DIR"
echo "------------------------"
cd $MODEL_DIR

SECONDS=0

echo "--- " 
echo "--- Running ADCIRC -----------------"
echo "---"

echo "---"
echo "------------------------"

echo "------------------------"
echo "--- "
echo "--- ADCPREP : Partmesh -----------------"
echo "---"

$EXEC/adcprep --np ${NPROCS} --partmesh
echo "---"
echo "------------------------"
echo "---"
echo "--- ADCPREP : Prepall -----------------"
echo "---"
$EXEC/adcprep --np ${NPROCS} --prepall
echo "---"

echo "------------------------"
echo "---"
echo "--- PADCIRC :  -----------------"
echo "---"
mpirun $MPIOPTS $EXEC/padcirc
echo "---"
echo "------------------------"


if [ $? -ne 0 ]; then
  echo "ERROR returned from mpirun"
else
  echo "ADCIRC model has succesfully completed on the cloud!"
  duration=$SECONDS
  echo "ADCIRC simulation took $((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
fi
