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

export MODEL_DIR=$SAVEDIR/$MODEL_VERSION

# Get the nosofs source code and scripts
cd $SAVEDIR
if [ ! -d $MODEL_DIR ]; then

  echo "Obtaining the source code, cloning the repository ... "
  git clone $REPO $MODEL_DIR
  cd $MODEL_DIR
  git checkout $BRANCH
  git submodule update --init --recursive

else
  echo "it appears $MODEL_DIR is already present, not fetching it from the repository"
fi


# Build it
echo "Building everything ... "
cp $CURHOME/modulefiles/intel_x86_64 $MODEL_DIR/modulefiles/intel_x86_64
cd $MODEL_DIR/sorc

echo "The build scripts can be modified to only build specific models."
./build.sh



# Obtain the fixed field files
# ----------------------------
# These files are too large to easily store on github.
# You can run the below script to download all of the fixed field files from the IOOS-cloud-sandbox S3 bucket.
# You can edit the script to only download a subset.

mkdir -p $SAVEDIR/$MODEL_DIR/fix
cd $SAVEDIR/$MODEL_DIR/fix

echo "Retrieving the fixed field files from S3"
$CURHOME/get_fixfiles_s3.sh


