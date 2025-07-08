#!/usr/bin/env bash

module use /save/patrick/Cloud-Sandbox/models/secofs/modulefiles
MODULEFILE=intel_x86_64_mpi-2021.12.1-intel-2021.9.0
module load $MODULEFILE

cd /com/patrick/secofs/20171201/outputs

/save/patrick/schism/bin/combine_hotstart7 -i 720
if [ $? -eq 0 ]; then
   # Remove the parts
   rm hotstart_??????_720.nc
fi

mv 'hotstart_it=720.nc' hotstart.nc

# tested: it will NOT restart with the pieces when using same cluster config
mv hotstart.nc ..

