#!/bin/bash
# redirect stdout/stderr to a file
# This was for an ADCIRC hurricane Florence test case
exec &> /save/adcirc-ClusterRPS/fcst_adcirc_log.txt

set -x
ulimit -s unlimited
ulimit -c unlimited

. /usr/share/Modules/init/bash

module load gcc/6.5.0 
module load mpi/intel/2020.0.166 
module load netcdf/4.5 
module load hdf5/1.10.5 

PHOME=/save/adcirc-cg/work
ROTDIR=/save/adcirc-florence-input/


echo "------------------------"
echo "---" 
module list
echo "---" 
echo "------------------------"
echo "--- " 
echo "--- Path to mpif90  --------"
which mpif90
echo "--- " 
echo "------------------------"

COMOUT=/com/adcirc/$CDATE$HH
PTMP=/ptmp/adcirc/$CDATE$HH

mkdir -p $COMOUT

# Making PTMP folder
if [ -e $PTMP ]; then rm -Rf $PTMP; fi
mkdir -p $PTMP

curdir=$PWD

echo "NPROCS is $NPROCS"

# Copy the inputs to PTMP
cd $ROTDIR
cp -p * $PTMP

cd $PTMP

echo "--- Removing previous PE dirs, if any --------"
echo "---" 
rm -rf PE* *.nc

ln -fs /save/adcirc-florence/tidalSpinup/fort.68.nc .

echo "---" 
echo "------------------------"

echo "------------------------"
echo "--- " 
echo "--- ADCPREP : Partmesh -----------------"
echo "---"

mpirun --hosts ${HOSTS} -np ${NPROCS} $PHOME/adcprep --np ${NPROCS} --partmesh
echo "---" 
echo "------------------------"
echo "---" 
echo "--- ADCPREP : Prepall -----------------"
echo "---" 
mpirun --hosts ${HOSTS} -np ${NPROCS} $PHOME/adcprep --np ${NPROCS} --prepall
echo "---" 

echo "------------------------"
echo "---" 
echo "--- PADCIRC/PADCSWAN :  -----------------"
echo "---" 
mpirun --hosts ${HOSTS} -np ${NPROCS} $PHOME/padcirc --np ${NPROCS}
echo "---" 
echo "------------------------"

if [ $? -ne 0 ]; then
  echo "ERROR returned from mpirun"
else
  rm -rf PE*
  mv $PTMP/* $COMOUT
  cd $COMOUT
  rm -Rf $PTMP
fi
