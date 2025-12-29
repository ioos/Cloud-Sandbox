#!/bin/env bash
#set -x

export TOPDIR=${PWD}
export MODEL_DIR=/save/$USER/liveocean
mkdir -p $MODEL_DIR

# COMDIR is needed by get_LiveOcean_data.sh
export COMDIR=${COMDIR:-/com/liveocean}

./get_LO_ROMS.sh
cd $TOPDIR
exit

./LO_COMPILE.sh
cd $TOPDIR

./get_LiveOcean_data.sh
cd $TOPDIR

