#!/usr/bin/env bash
set -e

HOMEDIR=$(dirname $PWD)
HOMELIBS=$HOMEDIR/libs

export MODEL_DIR=/save/$USER/necofs/NECOFS_v2.4/hindcast/FVCOMv4.4.8

cp -p hindcasts.make.inc $MODEL_DIR/src/make.inc
cd $MODEL_DIR/src || exit 1

module use -a $HOMEDIR/modulefiles
module load intel_x86_64.impi_2021.12.1

# module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-aimw7vu 
# module load petsc/3.21.1-oneapi-2023.1.0-47el2ee
#make depends # makedepends files are already there - need to compile makedepf90 from source
# https://github.com/outpaddling/makedepf90

# Build the julian calendar library
cd  $MODEL_DIR/src/libs
if [ ! -d julian ]; then
  tar -xvf julian.tgz
  cd  $MODEL_DIR/src/libs/julian || exit 1

  make clean
  make -f makefile
  if [ -s libjulian.a ]; then
    echo "libjulian created"
  else
    echo "WARNING: libjulian.a was not created"
  fi
  rm -f *.o
fi

cd $MODEL_DIR/src
make clean
make depend
make

mv fvcom ../necofs_fvcom
