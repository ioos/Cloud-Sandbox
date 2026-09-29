#!/bin/sh
#set -x

export nosofs_ver=3.6.6
export HOMEnos=$(dirname $(dirname $PWD))
export HOMEnos=${HOMEnos:-${PACKAGEROOT:?}/nosofs.${nosofs_ver:?}}

#export HOMEnos=/lfs/h1/nos/nosofs/noscrub/$LOGNAME/packages/nosofs.v3.7.2
#cd ../..
#HOMEnos=`pwd`
#export HOMEnos=${HOMEnos:-${PACKAGEROOT:?}/nosofs.${nosofs_ver:?}}
#export HOMEnos=/lfs/h1/nos/nosofs/noscrub/aijun.zhang/tmp/roms

BUILD_VERSION_FILE=$HOMEnos/versions/build.ver
if [ -f $BUILD_VERSION_FILE ]; then
 . $BUILD_VERSION_FILE
else
   echo " Build Version File $BUILD_VERSION_FILE does not exist **"
   exit
fi

module purge
module use -a $HOMEnos/modulefiles
module load intel_x86_64

export SORCnos=$HOMEnos/sorc
export EXECnos=$HOMEnos/exec
export LIBnos=$HOMEnos/lib

if [[ $(nproc) -eq 1 || $(nproc) -eq 2 ]]; then
    JOBS=1
else
    JOBS=$(($(nproc) - 1))
fi

models='eccofs'

for model in $models
do

  echo ""
  echo "Compiling ROMS ocean model for ${model^^}"
  echo "------------------------------------------------"
  if [[ $model == "eccofs" ]]; then
    cd $SORCnos/ROMS.eccofs
  else
    cd $SORCnos/ROMS.fd
  fi
  ./build_${model}.sh -j $JOBS
  if [ -s ${model}_roms_mpi ]; then
    mv ${model}_roms_mpi $EXECnos/.
  else
    echo "error: roms executable for ${model^^} is not created"
  fi
done
