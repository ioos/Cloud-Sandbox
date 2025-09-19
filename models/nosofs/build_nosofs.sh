#!/usr/bin/env bash
set -euo pipefail

# This script can be used to rerun the nosofs build

export SAVEDIR=${1:-"/save/$USER"}
if [ ! -d $SAVEDIR ]; then
    mkdir -p $SAVEDIR | echo "Can not create $SAVEDIR"; exit 1
fi

export CURHOME=$PWD
export CSHOME="${PWD%/*/*}"
echo "Cloud-Sandbox/ directory is: $CSHOME"

export REPO="https://github.com/asascience-open/NOSOFS-Code-Package.git"
export BRANCH="v3.6.6.dev"
export MODEL_VERSION='nosofs.v3.6.6'

export MODEL_DIR=$SAVEDIR/$MODEL_VERSION

cd $SAVEDIR
if [ ! -d $MODEL_DIR ]; then
  echo "it appears $MODEL_DIR is missing"
  exit 1
fi

cp $CURHOME/modulefiles/intel_x86_64 $MODEL_DIR/modulefiles/intel_x86_64
cd $MODEL_DIR/sorc

echo "Building everything ... "
echo "The build scripts can be modified to only build specific models."
./build.sh

