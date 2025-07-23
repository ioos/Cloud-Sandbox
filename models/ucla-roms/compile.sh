#!/bin/bash

export ROMS_ROOT=/save/$USER/ucla-roms

module purge
module use -a /mnt/efs/fs1/save/environments/spack/share/spack/modules/linux-rhel8-x86_64
module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3a7dxu3
module load intel-oneapi-mpi/2021.9.0-intel-2021.9.0-egjrbfg
module load bzip2/1.0.8-intel-2021.9.0-jky2iw7 lz4/1.9.4-intel-2021.9.0-a7shfis
module load snappy/1.1.10-intel-2021.9.0-67s3jwz
module load zstd/1.5.5-intel-2021.9.0-x3khtnn
module load c-blosc/1.21.5-intel-2021.9.0-ltu7tzq
module load netcdf-c/4.9.2-intel-2021.9.0-vznmeik
module load netcdf-fortran/4.6.1-intel-2021.9.0-meeveoj
export LD_LIBRARY_PATH=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-fortran-4.6.1-meeveojv5q6onmj6kitfb2mwfqscavn6/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vznmeikm7cp5ht2ktorgf2ehhzgvqqel/lib:$LD_LIBRARY_PATH
export FC=mpiifort
export CXX=mpiicpc
export CC=mpiicc

make COMPILER=ifort MPI_WRAPPER=mpiifort
