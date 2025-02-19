#!/usr/bin/env bash

#ADCIRCHome=/save/ec2-user/adcirc
ADCIRCHome=/save/patrick/adcirc

if [ ! $ADCIRCHome ]; then
  echo "Set ADCIRCHome variable before running"
  exit
fi

ls "$ADCIRCHome/work" || exit 1
cp cmplrflags.mk $ADCIRCHome/work

# NETCDFHOME Sets the home path for netCDF C and Fortran libraries. This assumes that the libraries are installed to the same location. This folder should contain the folders "lib" and "include
# Need to create symlinks to netcdf-fortran include and lib files

export NETCDFHOME="/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vznmeikm7cp5ht2ktorgf2ehhzgvqqel"

#export I_MPI_F90=mpiifort
export I_MPI_F90=ifort
export CMAKE_INSTALL_PREFIX="${ADCIRCHome}/work"

echo $PWD
module use -a $PWD
#module load intel_x86_64
module load intel_x86_64.impi_2021.12.1

cp cmplrflags.mk $ADCIRCHome/work

cd "$ADCIRCHome" || exit 1

if [ ! -e build ]; then
    mkdir build
fi

cd build

# Might need to clean first
# make clean

cmake .. -DBUILD_PADCIRC=ON \
	 -DBUILD_PADCSWAN=ON \
         -DBUILD_ADCPREP=ON \
	 -DBUILD_ADCSWAN=OFF \
         -DENABLE_OUTPUT_NETCDF=ON \
         -DBUILD_UTILITIES=ON \
         -DCMAKE_C_COMPILER=icc -DCMAKE_CXX_COMPILER=icc -DCMAKE_Fortran_COMPILER=ifort
make

