#!/usr/bin/env bash

# Full ECCOFS https://github.com/myroms/roms_eccofs/blob/develop/RBL4DVAR_mixres/Readme.md
#
# USED subgrid of ECCOFS original one: https://github.com/myroms/roms_test/blob/main/USEC/RBL4DVAR_mixres/Readme.md

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

# export BRANCH="main"

export MODULEFILE=intel_x86_64

# Build scripts and test case data and 
export USEC_REPO="https://github.com/myroms/roms_test.git"
export MODEL_DIR=$SAVEDIR/eccofs-usec

# /save/ec2-user/eccofs-usec/USEC/RBL4DVAR_mixres
export EXP_DIR=$MODEL_DIR/USEC/RBL4DVAR_mixres

export ROMS_REPO="https://github.com/asascience-open/roms.git"
export ROMS_BRANCH="sandbox-eccofs"

export ROMS_ROOT_DIR=$MODEL_DIR

# Get the roms_eccofs repo with mixres, test data, and build files.
cd $SAVEDIR
if [ ! -d $MODEL_DIR ]; then
  # git clone --depth 1 --filter=blob:none --sparse $USEC_REPO eccofs-usec

  git clone --depth 1 --filter=blob:none --no-checkout $USEC_REPO eccofs-usec
  cd eccofs-usec
  git sparse-checkout init --cone
  git sparse-checkout set USEC
  git lfs pull --include="USEC/**"
else
  echo "eccofs-usec already present... "
  echo "... not fetching $ECCOFS_REPOi/USEC"
fi

exit

# Copy our modified script to repo for now
cp -pf $CURHOME/submit_mixres_rbl4dvar.sh $EXP_DIR

cd $CURHOME

# Get the ROMS source code and scripts
cd $SAVEDIR
if [ ! -d $MODEL_DIR ]; then
  echo "ERROR: $MODEL_DIR not present ... exiting"
else
  cd $MODEL_DIR
  if [ ! -d $MODEL_DIR/roms ]; then
    git clone $ROMS_REPO roms
    cd roms
    git checkout $ROMS_BRANCH
  else
    echo "$MODEL_DIR/roms already present"
  fi
fi
cd $CURHOME


# Build it
# --------

if [ ! -d $EXP_DIR/modulefiles ]; then
  mkdir $EXP_DIR/modulefiles
fi
cp -pf $CURHOME/modulefiles/$MODULEFILE $EXP_DIR/modulefiles


#echo "PT testing: skipping build."
echo "Building eccofs ... "
./build_eccofs-da.sh

echo "Done."

