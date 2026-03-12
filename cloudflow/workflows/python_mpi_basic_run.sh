#!/bin/bash
# redirect stdout/stderr to a file
#exec &> /save/ec2-user/OWP/laura/schism_cloud_sandbox_log.txt

set -e       # exit immediately on error
set -x       # verbose with command expansion
set -u       # forces exit on undefined variables

export SCRIPT=$1
export EXEC=$2

SECONDS=0

# Load the modules that were used to linked mpi4py
# Message Passing Interface implementation within 
# your Python environment as well as the respective
# libraries linked to the MPI executables
module purge
module use -a /mnt/efs/fs1/save/environments/spack.v0.22.5/share/spack/modules/linux-rhel8-x86_64

module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3rbcwfi
module load intel-oneapi-mpi/2021.12.1-intel-2021.9.0-6nra3z4
module load hdf5/1.14.3-intel-2021.9.0-jjst2zs
module load netcdf-c/4.9.2-intel-2021.9.0-vkckbzk
module load netcdf-fortran/4.6.1-intel-2021.9.0-cpxxwci



echo "--- " 
echo "--- Running PYTHON Script -----------------"
echo "---"

mpirun $MPIOPTS $EXEC $SCRIPT


if [ $? -ne 0 ]; then
  echo "ERROR returned from Python mpirun"
else
  echo "Python script execution has succesfully completed on the cloud!"
  duration=$SECONDS
  echo "Python script execution took $((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
fi
