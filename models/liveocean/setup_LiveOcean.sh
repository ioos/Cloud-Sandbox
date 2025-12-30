#!/bin/env bash
set -euo pipefail
#set -x

export SAVEDIR=${1:-"/save/$USER"}
if [ ! -d $SAVEDIR ]; then
    mkdir -p $SAVEDIR | echo "Can not create $SAVEDIR"; exit 1
fi

export CURHOME=$PWD
export CSHOME="${PWD%/*/*}"
echo "Cloud-Sandbox/ directory is: $CSHOME"

export MODULEFILE=intel_x86_64
export MODEL_DIR=$SAVEDIR/LiveOcean

# COMDIR is needed by get_LiveOcean_data.sh
export COMDIR=${COMDIR:-/com/liveocean}

# Get the LiveOcean scripts
cd $SAVEDIR
if [ ! -d $MODEL_DIR ]; then

  export REPO="https://github.com/asascience/LiveOcean.git"
  export BRANCH="main"

  echo "Obtaining the LiveOcean scripts, cloning the repository ... "
  git clone $REPO $MODEL_DIR
  cd $MODEL_DIR
  git checkout $BRANCH

else
  echo "$MODEL_DIR is already present, not fetching it from the repository"
fi
cd $CURHOME


# Get the LiveOcean source code
./get_LO_ROMS.sh
cd $CURHOME


./LO_COMPILE.sh
cd $CURHOME


./get_LiveOcean_data.sh
cd $CURHOME

cp -p modulefiles/* $MODEL_DIR/modulefiles/
