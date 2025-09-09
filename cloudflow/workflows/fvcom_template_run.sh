#!/bin/bash
# redirect stdout/stderr to a file
#exec &> /save/ec2-user/OWP/laura/schism_cloud_sandbox_log.txt

set -e       # exit immediately on error
set -x       # verbose with command expansion
set -u       # forces exit on undefined variables

module purge
module use -a /mnt/efs/fs1/save/environments/spack.v0.22.5/share/spack/modules/linux-rhel8-x86_64

module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3rbcwfi
module load intel-oneapi-mpi/2021.12.1-intel-2021.9.0-6nra3z4
module load hdf5/1.14.3-intel-2021.9.0-jjst2zs
module load netcdf-c/4.9.2-intel-2021.9.0-vkckbzk
module load netcdf-fortran/4.6.1-intel-2021.9.0-cpxxwci

export FC=mpiifort
export CXX=mpiicpc
export CC=mpiicc

export LD_LIBRARY_PATH=/mnt/efs/fs1/save/environments/spack.v0.22.5/opt/spack/__spack_path_place/linux-rhel8-x86_64/intel-2021.9.0/netcdf-fortran-4.6.1-cpxxwcig5kifogteqpenkxw35q6tthgt/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/mnt/efs/fs1/save/environments/spack.v0.22.5/opt/spack/__spack_path_place/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vkckbzk37srvezgw4yt7existfejyque/lib:$LD_LIBRARY_PATH

export I_MPI_OFI_LIBRARY_INTERNAL=0   # Using AWS EFA Fabric on AWS
export FI_PROVIDER=efa
export I_MPI_FABRICS=ofi
export I_MPI_OFI_PROVIDER=efa


export MODEL_DIR=$1
export CASE_FILE=$2
export EXEC=$3

echo "---" 
echo "------------------------"
echo "FVCOM model working directory is $MODEL_DIR"
echo "------------------------"
cd $MODEL_DIR

SECONDS=0

echo "--- " 
echo "--- Running FVCOM -----------------"
echo "---"

mpirun $MPIOPTS $EXEC --casename=$CASE_FILE


if [ $? -ne 0 ]; then
  echo "ERROR returned from mpirun"
else
  echo "FVCOM model has succesfully completed on the cloud!"
  duration=$SECONDS
  echo "FVCOM simulation took $((duration / 60)) minutes and $((duration % 60)) seconds elapsed."
fi
