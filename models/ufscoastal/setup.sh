#!/usr/bin/env bash
# set -e
#set -euo pipefail
#set -x

# https://ufs-coastal-application.readthedocs.io/en/latest/index.html

# Use this to:

# If you are using a shared "USER" account, make sure to
# set the below path to your own SAVE space 
# or provide it as a command argument

export SAVEDIR=${1:-"/save/$USER"}
if [ ! -d $SAVEDIR ]; then
    mkdir -p $SAVEDIR | echo "Can not create $SAVEDIR"; exit 1
fi

export CURHOME=$PWD
export CSHOME="${PWD%/*/*}"
echo "Cloud-Sandbox/ directory is: $CSHOME"

export REPO="https://github.com/asascience-open/ufs-weather-model.git"
export BRANCH="ioossb_coastal"

#module use -a /save/ec2-user/Cloud-Sandbox/models/ufscoastal/modulefiles
module use -a $CURHOME/modulefiles


cd $SAVEDIR

if [ ! -d ufs-weather-model ]; then
  git clone --recursive $REPO
  git checkout $BRANCH
else
  echo "ufs-weather-model already present, not fetching from github"
fi

cd ufs-weather-model

# Copy the modulefiles that work with this deployment
# Build modules are same modulefiles with different name/location
cp -p $CURHOME/modulefiles/lua/ufs_ioossb.intel.lua modulefiles/
cp -p $CURHOME/modulefiles/lua/ufs_ioossb.intelllvm.lua modulefiles/

cp -p $CURHOME/modulefiles/lua/ufs_ioossb.intel.lua tests/modules.fv3_atm2roms_intel.lua

cp -p $CURHOME/modulefiles/lua/ufs_ioossb.intel.lua tests/modules.fv3_atm2sch_intel.lua
cp -p $CURHOME/modulefiles/lua/ufs_ioossb.intelllvm.lua tests/modules.fv3_atm2sch_intelllvm.lua

# SCHISM needed some help to use our metis, paramatis libraries
cp -p $CURHOME/FindMETIS.cmake $SAVEDIR/ufs-weather-model/SCHISM-interface/SCHISM/cmake/modules

module purge
#module load ufs_ioossb.intel.tcl
module load lua/ufs_ioossb.intel
#module load lua/ufs_ioossb.intelllvm
module list

# https://ufs-coastal-application.readthedocs.io/en/latest/BuildingAndRunning.html#setting-the-cmake-flags-environment-variable

# ROMS supported
#APP CSTLR = Coastal ROMS - ifort only 
export CMAKE_FLAGS="-DAPP=CSTLR -DMY_CPP_FLAGS=BULK_FLUXES -DCMAKE_AR=xiar -DCMAKE_RANLIB=xild"

# SCHISM supported
#APP CSTLS = Cstl SCHISM -  builds ifort and ifx
#export CMAKE_FLAGS="-DAPP=CSTLS -DUSE_ATMOS=ON -DNO_PARMETIS=OFF -DOLDIO=OFF"
#

# Not yet tested
#APP CSTLF = Cstl FVCOM
# export CMAKE_FLAGS="-DAPP=CSTLF -DCOORDINATE_TYPE=SPHERICAL -DWET_DRY=ON"
#APP CSTLA = Cstl ADCIRC
# export CMAKE_FLAGS="-DAPP=CSTLA -DADCIRC_CONFIG=PADCIRC -DCOUPLED=ON"

# cmake -DCMAKE_AR="xiar" -DCMAKE_RANLIB="xild" ..
#DCMAKE_AR
#export AR=/path/to/your/custom-ar
#
#spack env activate -p /save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8

./build.sh --platform=ioossb --compiler=intel

