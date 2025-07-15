#!/usr/bin/env bash

SAVE_DIR="/save/$USER/lapenta/"
MODULEFILE=nos.intel_x86_64_mpi-2021.12.1-intel-2021.9.0

if [ ! -d $SAVE_DIR ]; then
  echo "Error: $SAVE_DIR does not exist"
  exit 1
fi

SCRIPTS=$PWD

module use -a $SCRIPTS/modulefiles
module purge
module load $MODULEFILE

cd $SAVE_DIR/schism/cmake

cp $SCRIPTS/SCHISM.local.build .
cp $SCRIPTS/SCHISM.aws.ioos .

cd ..

if [ ! -e build ]; then
    mkdir build
fi
cd build

# Be careful not to delete wrong folder
if [ -f cmake_install.cmake ]; then 
  make clean
  rm -Rf * # Clean old cache
fi

cmake -DCMAKE_C_FLAGS="-diag-disable=10441" -DCMAKE_CXX_FLAGS="-diag-disable=10441" \
       -C ../cmake/SCHISM.local.build -C ../cmake/SCHISM.aws.ioos ../src/

make -j2

if [ ! -d ../bin ]; then
    mkdir ../bin
fi
cp -p bin/* ../bin/

cp -p $SCRIPTS/modulefiles/$MODULEFILE $SAVE_DIR/schism

# icc: remark #10441: The Intel(R) C++ Compiler Classic (ICC) is deprecated and will be removed from product release in the second half of 2023. The Intel(R) oneAPI DPC++/C++ Compiler (ICX) is the recommended compiler moving forward. Please transition to use this compiler. Use '-diag-disable=10441' to disable this message.
# icc: command line warning #10006: ignoring unknown option '-cpp'
