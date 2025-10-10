#!/usr/bin/env bash
set -euo pipefail

# Use this to:
#   fetch the operational NOSOFS source codes
#   build the models and other executables needed by the production suite
#   retrieve the fixed fields needed to run the models
#   
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

export REPO="https://github.com/asascience-open/NOSOFS-Code-Package.git"
export BRANCH="v3.6.6.dev"
export MODEL_VERSION='nosofs.v3.6.6'
export MODULEFILE=intel_x86_64

export MODEL_DIR=$SAVEDIR/$MODEL_VERSION

# Get the nosofs source code and scripts
cd $SAVEDIR
if [ ! -d $MODEL_DIR ]; then

  echo "Obtaining the NOSOFS source code, cloning the repository ... "
  git clone $REPO $MODEL_DIR
  cd $MODEL_DIR
  git checkout $BRANCH
  git submodule update --init --recursive

else
  echo "$MODEL_DIR is already present, not fetching it from the repository"
fi

### TODO add ECCOFS as submodule to nosofs
## Clone the ROMS used for eccofs
#if [ ! -d $MODEL_DIR/sorc/ROMS.eccofs ]; then
#
#  echo "Obtaining the ECCOFS ROMS source code ... "
#  cd $MODEL_DIR/sorc
#  git clone -b ioos-sandbox-eccofs https://github.com/asascience-open/roms.git ROMS.eccofs
#
#else
#  echo "$MODEL_DIR/sorc/ROMS.eccofs is already present, not fetching it from the repository"
#fi

cp $CURHOME/modulefiles/$MODULEFILE $MODEL_DIR/modulefiles/intel_x86_64

# Build it
# echo "Building eccofs ... "
cd $MODEL_DIR/sorc/ROMS.eccofs
./COMPILE_ROMS.sh

# Get test-case data

