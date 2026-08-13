#!/usr/bin/env bash

# https://github.com/myroms/roms_eccofs/blob/develop/RBL4DVAR_mixres/Readme.md
#
# Older/original one: https://github.com/myroms/roms_test/blob/main/USEC/RBL4DVAR_mixres/Readme.md

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

### DELETE THIS REPO - changed my mind export REPO="https://github.com/asascience-open/eccofs-da.git"
# export BRANCH="main"

export MODULEFILE=intel_x86_64

# Build scripts and test case data and 
export ECCOFS_REPO="https://github.com/myroms/roms_eccofs.git"
export MODEL_DIR=$SAVEDIR/roms_eccofs
export EXP_DIR=$MODEL_DIR/RBL4DVAR_mixres

export ROMS_REPO="https://github.com/asascience-open/roms.git"
# From Haibo: 3eaf9c5 (maybe they used this for USEC)
# From Julia: bf66be4
# Testing 32c79b7
# Author: Hernan G. Arango <arango@marine.rutgers.edu>
# Date:   Sat Apr 25 16:40:18 2026 -0400
#    Forcing the closing of the INI and ITL files in 4D-Var (#76)

# sandbox-eccofs - from working eccofs
# 148a4614 (HEAD -> sandbox-eccofs, origin/sandbox-eccofs) added JOBS to compile
# 701cfb3e updated roms
# d06fee85 Adding Estuarine Carbon Biogeochemical Model (ECB) (#61)
# commit d06fee857acc8468dbf418ec5b5ee72766671256
# Author: Hernan G. Arango <arango@marine.rutgers.edu>
# Date:   Fri Jun 27 23:05:36 2025 -0400
#    Adding Estuarine Carbon Biogeochemical Model (ECB) (#61)

export ROMS_BRANCH="eccofs-da"

export ROMS_ROOT_DIR=$MODEL_DIR

# Get the roms_eccofs repo with mixres, test data, and build files.
cd $SAVEDIR
if [ ! -d $MODEL_DIR ]; then
  git clone $ECCOFS_REPO
else
  echo "roms_eccofs already present... "
  echo "... not fetching $ECCOFS_REPO"
fi

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

