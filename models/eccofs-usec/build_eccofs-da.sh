#!/usr/bin/env bash

# This script can be called directly or via the setup script

# Use this to:
#   build the models and other executables needed by the production suite
#   retrieve the fixed fields needed to run the models

# If you are using a shared "USER" account, make sure to
# set the below path to your own SAVE space 
# or provide it as a command argument

export SAVEDIR=${SAVEDIR:-"/save/$USER"}
export CURHOME=$PWD
export CSHOME="${PWD%/*/*}"
echo "Cloud-Sandbox/ directory is: $CSHOME"

export MODULEFILE=${MODULEFILE:=intel_x86_64}
export MODEL_DIR=${MODEL_DIR:-$SAVEDIR/roms_eccofs}
export EXP_DIR=${EXP_DIR:-$MODEL_DIR/RBL4DVAR_mixres}
export ROMS_ROOT_DIR=${ROMS_ROOT_DIR:-$MODEL_DIR}

if [ ! -d $MODEL_DIR/roms ]; then
  echo "ERROR: $MODEL_DIR is missing"
  exit 1
fi

if [ ! -d $EXP_DIR ]; then
  echo "ERROR: $EXP_DIR is missing"
  exit 1
fi

# Build it
##########

cp -pf $CURHOME/Linux-ifort.mk $ROMS_ROOT_DIR/roms/Compilers

mkdir $EXP_DIR/modulefiles
cp -p $CURHOME/modulefiles/$MODULEFILE $EXP_DIR/modulefiles

cp $CURHOME/build_split.sh $EXP_DIR
cd $EXP_DIR

module use -a modulefiles
module load $MODULEFILE

if [[ $(nproc) -eq 1 || $(nproc) -eq 2 ]]; then
    JOBS=1
else
    JOBS=$(($(nproc) - 1))
fi

USEPIO="-pio"
USEPIO=""

./build_split.sh -nl -g $USEPIO -j $JOBS    # creates executable romsM_nl
result=$?
echo "romsM_nl build finished - $result"
echo "---------------------------------"
echo "---------------------------------"
echo "---------------------------------"
echo "---------------------------------"

./build_split.sh -da -g $USEPIO -j $JOBS    # creates executable romsM_da
result=$?
echo "romsM_da build finished - $result"
echo "---------------------------------"
echo "---------------------------------"
echo "---------------------------------"
echo "---------------------------------"

