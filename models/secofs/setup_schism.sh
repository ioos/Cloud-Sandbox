#!/usr/bin/env bash
set -eux

export CURHOME=$PWD
export CSHOME="${PWD%/*/*}"
echo "Cloud-Sandbox/ directory is: $CSHOME"

# This is for the files under /save
export MODEL_DIR=${MODEL_DIR:-"/save/$USER"}

# This is for IC and forcing data under /com
export DATA_DIR=${DATA_DIR:-"/com/$USER"}

./get_schism.sh
#cd $CURHOME

./build_schism.sh
#cd $CURHOME

./get_testcase_inputs.sh
#cd $CURHOME


