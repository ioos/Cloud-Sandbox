#!/usr/bin/env bash
set -euo pipefail

SAVEDIR=${1:-"/save/$USER"}
if [ ! -d $SAVEDIR ]; then
    mkdir -p $SAVEDIR | echo "Can not create $SAVEDIR"; exit 1
fi

CURHOME=$PWD
CSHOME="${PWD%/*/*}"
echo "Cloud-Sandbox/ directory is: $CSHOME"

REPO="https://github.com/asascience-open/NOSOFS-Code-Package.git"
BRANCH="v3.6.6.dev"
MODEL_VERSION='nosofs.v3.6.6'

MODEL_DIR=$SAVEDIR/$MODEL_VERSION

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


# TODO: synchronize these or something
# cp $CURHOME/modulefiles/intel_x86_64 $MODEL_DIR/modulefiles/
cd $MODEL_DIR/sorc


echo "Building everything ... "
echo "The build scripts can be modified to only build specific models."
./build.sh


#./ROMS_COMPILE.sh
#./FVCOM_COMPILE.sh

# Obtain the fixed field files (too large for gitHub)
# mkdir -p $SAVEDIR/$MODEL_DIR/fix
# cd $SAVEDIR/$MODEL_DIR/fix

### Obtain the Fixed Field Files
# These files are too large to easily store on github and need to be obtained elsewhere.
# You can run the below script to download all of the fixed field files from the IOOS-cloud-sandbox S3 bucket.
# Edit the script to only download a subset.
# This is already in the nosofs repo
## $CURHOME/get_fixfiles_s3.sh

# bash get_fixfiles_s3.sh

