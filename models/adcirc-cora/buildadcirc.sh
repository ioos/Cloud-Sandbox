#!/usr/bin/env bash

#ADCIRCHome=/save/patrick/adcirc
#ADCIRCHome=/save/ec2-user/adcirc

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

module purge

module use -a ../modulefiles
module load intel_x86_64.impi_2021.12.1

if [ -d $NETCDF ] && [ -d $NETCDFC ]; then
    ln -s $NETCDF/lib/libnetcdff* $NETCDFC/lib >& /dev/null
    ln -s $NETCDF/include/* $NETCDFC/include >& /dev/null
    cd $home
else
    echo "WARNING: Could not create symbolic links for netcdf libraries"
fi

export NETCDFHOME=$NETCDFC

cd "$ADCIRCHome" || exit 1

if [ ! -e build ]; then
    mkdir build
fi

cd build

CMAKEOPTS=''
#CMAKEOPTS='--trace'
# --log-level=<ERROR|WARNING|NOTICE|STATUS|VERBOSE|DEBUG|TRACE>
#  --trace                      = Put cmake in trace mode.
#  --trace-expand               = Put cmake in trace mode with variable
#                                 expansion.

cmake $CMAKEOPTS .. \
	 -DBUILD_PADCIRC=ON \
	 -DBUILD_PADCSWAN=ON \
         -DBUILD_ADCPREP=ON \
	 -DBUILD_ADCSWAN=OFF \
         -DENABLE_OUTPUT_NETCDF=ON \
         -DBUILD_UTILITIES=ON \
         -DCMAKE_C_COMPILER=icc -DCMAKE_CXX_COMPILER=icc -DCMAKE_Fortran_COMPILER=ifort

make clean

make

# installs into <prefix>/bin
make install

# Hack fix for now
cp -p $CMAKE_INSTALL_PREFIX/bin/* $ADCIRCHome/work


