#!/usr/bin/env bash

. /save/environments/spack/share/spack/setup-env.sh

# spack load cmake@3.23.1%intel@2021.3.0
# spack load intel-oneapi-compilers@2021.3.0
# spack load intel-oneapi-mpi@2021.3.0%intel@2021.3.0

module load cmake-3.23.1-intel-2021.3.0-sszzhcn 
module load intel-oneapi-compilers-2021.3.0-gcc-8.5.0-gp3iweu
module load intel-oneapi-mpi-2021.3.0-intel-2021.3.0-bixgqcx

# spack load 

step-one () {
  mkdir -p ufs-release-v1.1.0/src
  cd ufs-release-v1.1.0/src
  git clone -b ufs-v1.1.0 https://github.com/NOAA-EMC/NCEPLIBS-external
  cd NCEPLIBS-external
  git submodule deinit hdf5
  git rm hdf5
  # Remove hdf5 from .gitmodules
  vim .gitmodules
  git checkout -b ioos-sandbox
  git add -A
  git commit -m "removed inaccessible hdf5 submodule"
  git submodule update --init --recursive
}

# Download and unzip hdf5 CMake source into hdf5 folder.

cd /save/ufs-release-v1.1.0/src/NCEPLIBS-external
# mkdir build

export CC=icc
export FC=ifort
export CXX=icpc

export MPI_FC=mpiifort
export MPI_CC=mpiicc
export MPI_CXX=mpiicpc

export MPI_ROOT=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-centos7-skylake_avx512/intel-2021.3.0/intel-oneapi-mpi-2021.3.0-bixgqcxgye22fps3mfvauu7kka6ywjwy/mpi/2021.3.0

module load netcdf-c-4.8.0-intel-2021.3.0-hkwktas
module load netcdf-fortran-4.5.4-intel-2021.3.0-4lyzqsf

export NETCDF=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-centos7-skylake_avx512/intel-2021.3.0/netcdf-c-4.8.0-hkwktas6zil5xfhkp3nofqztfykwb7be
export NETCDF_FORTRAN=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-centos7-skylake_avx512/intel-2021.3.0/netcdf-fortran-4.5.4-4lyzqsfbjwtzdw7r74mk2n52cb2aqyli

module load libpng-1.6.37-gcc-8.5.0-daujf76
export LIBPNG_ROOT=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-centos7-skylake_avx512/gcc-8.5.0/libpng-1.6.37-daujf76lzlnhsjdxmhtkwklsprtui44h

module load esmf-8.2.0-intel-2021.3.0-w6iewjl

# export ESMFMKFILE=
# netcdf-c-4.8.0-intel-2021.3.0-hkwktas
# netcdf-c-4.8.0-intel-2021.3.0-pejnxdb

#cmake -DBUILD_MPI=OFF -DCMAKE_INSTALL_PREFIX=/save/environments/ufs-mrw 2>&1 | tee log.cmake
# cmake -DBUILD_ESMF=OFF -DBUILD_MPI=OFF -DMPITYPE=intelmpi -DBUILD_PNG=OFF -DBUILD_NETCDF=OFF -DCMAKE_INSTALL_PREFIX=/save/environments/ufs-mrw

# make VERBOSE=1 -j4 2>&1 | tee log.make
#make depend
#make zlib
#make libjpeg
#make libpng
#make jasper
#make -j4 hdf5
#make -j4 esmf

#        @echo "... zlib"
#        @echo "... libjpeg"
#        @echo "... libpng"
#        @echo "... jasper"

#        @echo "The following are some of the valid targets for this Makefile:"
#        @echo "... all (the default if no target is provided)"
#        @echo "... clean"
#        @echo "... depend"
#        @echo "... edit_cache"
#        @echo "... rebuild_cache"
#        @echo "... esmf"
#        @echo "... hdf5"
#        @echo "... mpi"
#        @echo "... netcdf"
#        @echo "... netcdf-fortran"
#        @echo "... wgrib2"


# make[3]: Entering directory `/mnt/efs/fs1/save/ufs-release-v1.1.0/src/NCEPLIBS-external/wgrib2'
# makefile:713: *** ERROR, get netcdf4 source by "wget ftp://ftp.unidata.ucar.edu/pub/netcdf/netcdf-4.6.1.tar.gz" .  Stop.
# make[3]: Leaving directory `/mnt/efs/fs1/save/ufs-release-v1.1.0/src/NCEPLIBS-external/wgrib2'

cd /mnt/efs/fs1/save/ufs-release-v1.1.0/src
#git clone -b ufs-v1.1.0 --recursive https://github.com/NOAA-EMC/NCEPLIBS
cd NCEPLIBS
#mkdir build
#cd build

cmake -DCMAKE_INSTALL_PREFIX=/save/environments/ufs-mrw -DEXTERNAL_LIBS_DIR=/save/environments/ufs-mrw  2>&1 | tee log.cmake
make -j4 2>&1 | tee log.make
# make install 2>&1 | tee log.install
