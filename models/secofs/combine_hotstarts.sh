#!/usr/bin/env bash

# This script will combine the hotstart file pieces into one file. 

MODEL_DIR=/save/$USER/schism
CDATE=20171201
COMOUT=/com/$USER/secofs/$CDATE
TIMESTEP=720

MODULEFILE=intel_x86_64

if [ ! -d $MODEL_DIR ]; then
  echo "Could not find MODEL_DIR : $MODEL_DIR"
  echo "Set in script"
fi

CURDIR=$PWD

module use $CURDIR/modulefiles
module load $MODULEFILE

cd $COMOUT/outputs

$MODEL_DIR/bin/combine_hotstart7 -i $TIMESTEP
if [ $? -eq 0 ]; then
   rm hotstart_??????_720.nc
fi

mv "hotstart_it=$TIMESTEP.nc" ../hotstart.nc

