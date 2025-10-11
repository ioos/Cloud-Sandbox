#!/usr/bin/env bash
set -euo pipefail

# Use this to:
#   build the models and other executables needed by the production suite
#   retrieve the fixed fields needed to run the models

# If you are using a shared "USER" account, make sure to
# set the below path to your own SAVE space 
# or provide it as a command argument

export SAVEDIR=${1:-"/save/$USER"}
export CURHOME=$PWD
export CSHOME="${PWD%/*/*}"
echo "Cloud-Sandbox/ directory is: $CSHOME"

export REPO="https://github.com/asascience-open/NOSOFS-Code-Package.git"
export BRANCH="v3.6.6.dev"
export MODEL_VERSION='nosofs.v3.6.6'
export MODULEFILE=intel_x86_64

export MODEL_DIR=$SAVEDIR/$MODEL_VERSION

# Get the nosofs source code and scripts
cd $SAVEDIR
if [ ! -d $MODEL_DIR ]; then
  echo "it appears $MODEL_DIR is missing"
  exit 1
fi

# Build it
cp $CURHOME/modulefiles/$MODULEFILE $MODEL_DIR/modulefiles/intel_x86_64

# This will also build some binaries used by the nosofs framework needed to run
cd $MODEL_DIR/sorc
./build-eccofs-only.sh

# The below can be used to just build the ROMS model
# cd $MODEL_DIR/sorc/ROMS.eccofs
# ./COMPILE_ROMS.sh

