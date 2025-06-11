#!/usr/bin/env bash

HOMEDIR=$PWD
HOMELIBS=$HOMEDIR/libs
#mkdir $HOMELIBS


PROJHOME=/save/patrick/necofs/sorc/tidal_barotropic/FVCOMv4.4.7.1

cd $PROJHOME/src || exit 1

cp $HOMEDIR/tidal_barotropic/make.inc .

module use -a $HOMEDIR/modulefiles
module load intel_x86_64.impi_2021.12.1
# module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-aimw7vu 
# module load petsc/3.21.1-oneapi-2023.1.0-47el2ee
#make depends # makedepends files are already there - need to compile makedepf90 from source
# https://github.com/outpaddling/makedepf90

# from nosofs

# cd  $PROJHOME/src/libs
# if [ ! -d julian ]; then
#  tar -xvf julian.tgz
#fi
#cd  $PROJHOME/src/libs/julian || exit 1

#gmake clean
#gmake -f makefile
#if [ -s libjulian.a ]; then
#  echo "libjulian created"
#  cp -p libjulian.a $HOMELIBS
#else
#  echo "WARNING: libjulian.a was not created"
#fi
#rm -f *.o

cd $PROJHOME/src
make clean
make depends
make



