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
export BRANCH=""

#module use -a /save/ec2-user/Cloud-Sandbox/models/ufscoastal/modulefiles
module use -a $CURHOME/modulefiles


cd $SAVEDIR

if [ ! -d ufs-weather-model ]; then
  git clone --recursive $REPO
else
  echo "ufs-weather-model already present, not fetching from github"
fi

cd ufs-weather-model

cp -p $CURHOME/modulefiles/lua/ufs_ioossb.intel.lua modulefiles/


module purge
#module load ufs_ioossb.intel.tcl
module load lua/ufs_ioossb.intel
module list

#APP CSTLR = Coastal ROMS - Tested - Passes
# export CMAKE_FLAGS="-DAPP=CSTLR -DMY_CPP_FLAGS=BULK_FLUXES -DCMAKE_AR=xiar -DCMAKE_RANLIB=xild"

# Not yet tested
#APP CSTLF = Cstl FVCOM
# export CMAKE_FLAGS="-DAPP=CSTLF -DCOORDINATE_TYPE=SPHERICAL -DWET_DRY=ON"

#APP CSTLA = Cstl ADCIRC
# export CMAKE_FLAGS="-DAPP=CSTLA -DADCIRC_CONFIG=PADCIRC -DCOUPLED=ON"

#APP CSTLS = Cstl SCHISM
# export CMAKE_FLAGS="-DAPP=CSTLS -DUSE_ATMOS=ON -DNO_PARMETIS=OFF -DOLDIO=ON"

APP=CSTLR
# https://ufs-coastal-application.readthedocs.io/en/latest/BuildingAndRunning.html#setting-the-cmake-flags-environment-variable
export CMAKE_FLAGS="-DAPP=$APP -DMY_CPP_FLAGS=BULK_FLUXES -DCMAKE_AR=xiar -DCMAKE_RANLIB=xild"


# cmake -DCMAKE_AR="xiar" -DCMAKE_RANLIB="xild" ..
#DCMAKE_AR
#export AR=/path/to/your/custom-ar

#which spack
#source /save/environments/spack-stack.v2.0/setup.sh
#which spack

# ar segfaults without the below line, ar tries to resolve built in math library with intel math library libmf and libimf
# source /opt/intel/oneapi/setvars.sh
# source /opt/rh/gcc-toolset-13/enable
#spack env activate -p /save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8

./build.sh --platform=ioossb --compiler=intel

# Just build.sh works with no arguments, have to set CMAKE flags, it probably doesn't get the platform specific cmake config
#./build.sh

