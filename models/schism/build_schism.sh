#!/usr/bin/env bash

#SAVEDIR="/save/$USER"

SAVEDIR="/save/patrick"

if [ ! -d $SAVEDIR ]; then
  echo "Error: $SAVEDIR does not exist"
  exit 1
fi

echo $PWD
CURDIR=$PWD

module use -a $PWD
module load intel_x86_64

cd $SAVEDIR
if [ ! -d $SAVEDIR/schism ]; then
  git clone https://github.com/schism-dev/schism.git
  # git clone --recurse-submodules https://github.com/schism-dev/schism.git
  cd schism
  get checkout tags/v5.11.1
  git submodule update --init --recursive

  # git clone --branch v2.0 --depth 1 --recurse-submodules https://github.com/user/repo.git
else
  echo "it appears schism is already present, not fetching it from the repository"
fi

cd schism/cmake
cp $CURDIR/SCHISM.local.build .
cp $CURDIR/SCHISM.aws.ioos .
cd ..

if [ ! -e build ]; then
    mkdir build
fi
cd build

# Be careful not to delete wrong folder
if [ -f cmake_install.cmake ]; then 
  rm -Rf * # Clean old cache
fi

#cmake -DCMAKE_WARN_DEV=OFF -C ../cmake/SCHISM.local.build -C ../cmake/SCHISM.aws.ioos ../src/
# -DCMAKE_C_FLAGS="-diag-disable=10441" -DCMAKE_CXX_FLAGS="-diag-disable=10441"
# Add the flag to the C and C++ compilers
#set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -diag-disable=10441")
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -diag-disable=10441")

cmake -DCMAKE_C_FLAGS="-diag-disable=10441" -DCMAKE_CXX_FLAGS="-diag-disable=10441" -C ../cmake/SCHISM.local.build -C ../cmake/SCHISM.aws.ioos ../src/

make -j1 pschism

#make VERBOSE=1 pschism # serial build with a lot of messages

# CMake Warning (dev) at /save/patrick/schism/cmake/SCHISM.local.build:37 (set):
#  implicitly converting 'BOOLEAN' to 'STRING' type.
#  This warning is for project developers.  Use -Wno-dev to suppress it.

# icc: remark #10441: The Intel(R) C++ Compiler Classic (ICC) is deprecated and will be removed from product release in the second half of 2023. The Intel(R) oneAPI DPC++/C++ Compiler (ICX) is the recommended compiler moving forward. Please transition to use this compiler. Use '-diag-disable=10441' to disable this message.
# icc: command line warning #10006: ignoring unknown option '-cpp'

# /save/patrick/schism/src/ParMetis-4.0.3/metis/GKlib/csr.c(796): warning #3180: unrecognized OpenMP #pragma
        #pragma omp parallel private(i, j, ncand, rsum, tsum, cand)
#        ^


