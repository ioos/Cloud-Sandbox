#!/usr/bin/env bash

#ADCIRCHome=/save/ec2-user/adcirc
ADCIRCHome=/save/patrick/adcirc

if [ ! $ADCIRCHome ]; then
  echo "Set ADCIRCHome variable before running"
  exit
fi

ls "$ADCIRCHome/work" || exit 1
cp cmplrflags.mk $ADCIRCHome/work

# specify the f90 compiler mpifort should use, otherwise it might use gfortran
export I_MPI_F90=ifort
export CMAKE_INSTALL_PREFIX="${ADCIRCHome}/work"

echo $PWD

module use -a ../modulefiles
module load intel_x86_64.impi_2021.12.1

# NETCDFHOME Sets the home path for netCDF C and Fortran libraries. This assumes that the libraries are installed to the same location. This folder should contain the folders "lib" and "include
# NETCDF envar is provided by the above module
# Need to create symlinks to netcdf-fortran include and lib files 
export NETCDFHOME=$NETCDF

cd "$ADCIRCHome" || exit 1

if [ ! -e build ]; then
    mkdir build
fi

cd build

# make clean

cmake .. -DBUILD_PADCIRC=ON \
	 -DBUILD_PADCSWAN=ON \
         -DBUILD_ADCPREP=ON \
	 -DBUILD_ADCSWAN=OFF \
         -DENABLE_OUTPUT_NETCDF=ON \
         -DBUILD_UTILITIES=ON \
         -DCMAKE_C_COMPILER=icc -DCMAKE_CXX_COMPILER=icc -DCMAKE_Fortran_COMPILER=ifort
# make

