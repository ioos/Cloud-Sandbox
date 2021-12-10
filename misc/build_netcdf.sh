#!/bin/env bash

# spack arch --known-targets
# example: spack install zlib%gcc@9.0.1 target=icelake
# target=skylake
#TARGET=skylake
#TARGET=core2
#TARGET=x86_64
#TARGET=broadwell
#TARGET=zen
TARGET=skylake_avx512

JOBS=4

#COMPILER='gcc@8.3.1'
COMPILER='intel@2021.3.0'

if [[ $COMPILER == 'intel@2021.3.0' ]]; then
  module load gcc/8.3.1
  module load compiler32/2021.3.0
fi

if [[ $COMPILER == 'gcc@8.3.1' ]]; then
  module load gcc/8.3.1
fi

spack install -j $JOBS netcdf-fortran%${COMPILER} ^netcdf-c@4.8.0%${COMPILER} ^hdf5@1.10.7%${COMPILER}~cxx+fortran+hl~ipo~java+shared+tools target=$TARGET
