#!/usr/bin/env bash

MODEL_DIR="/save/patrick"


if [ ! -d $MODEL_DIR ]; then
  echo "Error: $MODEL_DIR does not exist"
  exit 1
fi

echo $PWD
SCRIPTS=$PWD
MODULEFILE=intel_x86_64_impi_2023.1.0

cd $MODEL_DIR
if [ ! -d $MODEL_DIR/schism ]; then
  git clone https://github.com/schism-dev/schism.git
  #git clone --recurse-submodules https://github.com/schism-dev/schism.git
  cd schism
  git checkout tags/v5.13.0
  git submodule update --init --recursive
else
  echo "it appears schism is already present, not fetching it from the repository"
fi

module use -a $SCRIPTS/modulefiles
module purge
module load $MODULEFILE

cd $MODEL_DIR/schism/cmake

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

#make -j2 pschism
make -j2 all

if [ ! -d ../bin ]; then
    mkdir ../bin
fi
cp -p bin/* ../bin/

cp -p $SCRIPTS/modulefiles/$MODULEFILE $MODEL_DIR/schism

# icc: remark #10441: The Intel(R) C++ Compiler Classic (ICC) is deprecated and will be removed from product release in the second half of 2023. The Intel(R) oneAPI DPC++/C++ Compiler (ICX) is the recommended compiler moving forward. Please transition to use this compiler. Use '-diag-disable=10441' to disable this message.
# icc: command line warning #10006: ignoring unknown option '-cpp'
