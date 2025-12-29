#!/bin/bash
# set -x

TOPDIR=${TOPDIR:-${PWD}}
MODEL_DIR=${MODEL_DIR:-/save/$USER/liveocean}

BUILDDIR="${MODEL_DIR}/LO_roms_user/x4b"
BUILDSCRIPT=build_roms.sh
#BUILDOPTS='-j 2 -noclean'
BUILDOPTS='-j 2'

# BUILDOPTS
#    -j [N]      Compile in parallel using N CPUs                       :::
#                  omit argument for all available CPUs                 :::
#                                                                       :::
#    -p macro    Prints any Makefile macro value. For example,          :::
#                                                                       :::
#                  build_roms.sh -p FFLAGS                              :::
#                                                                       :::
#    -noclean    Do not clean already compiled objects 

export MY_ROOT_DIR=$MODEL_DIR
export MY_ROMS_SRC=${MY_ROOT_DIR}/LO_roms_source_git

# Using a different makefile for Sandbox
cp -p ./Compilers/Linux-ifort.mk $MY_ROMS_SRC/Compilers

export COMP_F=ifort
export COMP_F_MPI90=mpiifort
export COMP_F_MPI=mpiifort
export COMP_ICC=icc
export COMP_CC=icc
export COMP_CPP=cpp
export COMP_MPCC='mpicc -fc=icc'

# Compiler target machine
TARGETMX=${TARGETMX:-'x86_64'}
# TARGETMX=${TARGETMX:-'skylake_avx512'}
# TARGETMX='haswell'

. modulefiles/load_modules.sh

module list

NETCDF=`nf-config --prefix`
export NETCDF_INCDIR=`nf-config --includedir`
export NETCDF_LIBDIR="${NETCDF}/lib"

cd $BUILDDIR
./$BUILDSCRIPT $BUILDOPTS

