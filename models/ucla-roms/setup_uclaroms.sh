#!/bin/bash

###########################################################
# USER INPUT NEEDED: set where ucla-roms will be downloaded
###########################################################
export HOMEroms=/save/$USER/ucla-roms

########################
# load required modules
########################
module purge
module use -a /mnt/efs/fs1/save/environments/spack/share/spack/modules/linux-rhel8-x86_64
module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-3a7dxu3
module load intel-oneapi-mpi/2021.9.0-intel-2021.9.0-egjrbfg
module load bzip2/1.0.8-intel-2021.9.0-jky2iw7 lz4/1.9.4-intel-2021.9.0-a7shfis
module load snappy/1.1.10-intel-2021.9.0-67s3jwz
module load zstd/1.5.5-intel-2021.9.0-x3khtnn
module load c-blosc/1.21.5-intel-2021.9.0-ltu7tzq
module load netcdf-c/4.9.2-intel-2021.9.0-vznmeik
module load netcdf-fortran/4.6.1-intel-2021.9.0-meeveoj
export LD_LIBRARY_PATH=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-fortran-4.6.1-meeveojv5q6onmj6kitfb2mwfqscavn6/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/mnt/efs/fs1/save/environments/spack/opt/spack/linux-rhel8-x86_64/intel-2021.9.0/netcdf-c-4.9.2-vznmeikm7cp5ht2ktorgf2ehhzgvqqel/lib:$LD_LIBRARY_PATH
export FC=mpiifort
export CXX=mpiicpc
export CC=mpiicc


########################
# get ucla-roms repository from GitHub
########################

if [ ! -d $HOMEroms ]; then
    git clone https://github.com/CESR-lab/ucla-roms.git $HOMEroms
    if [ $? -ne 0 ]; then
        echo "Unable to clone the repository"
        exit 1
    fi
fi

cd $HOMEroms

export ROMS_ROOT=$HOMEroms

########################
# compile necessary tools for ucla-roms
########################

rsync -av ${ROMS_ROOT}/ci/ci_makefiles/ ${ROMS_ROOT}
cd Work/
make nhmg COMPILER=ifort MPI_WRAPPER=mpiifort

cd ${ROMS_ROOT}/Tools-Roms/

# change the references of “mpc” to “${ROMS_ROOT}/Tools-Roms/mpc”
sed -i 's/mpc/${ROMS_ROOT}\/Tools-Roms\/mpc/g' ../src/Makedefs.inc
make COMPILER=ifort MPI_WRAPPER=mpiifort


########################
# get input data for example cases
########################

cp ${ROMS_ROOT}/ci/get_input_files.sh ${ROMS_ROOT}/Examples/input_data/
cd ${ROMS_ROOT}/Examples/input_data/

# change the references of “partit” to “${ROMS_ROOT}/Tools-Roms/partit”
sed -i 's/partit/${ROMS_ROOT}\/Tools-Roms\/partit/g' get_input_files.sh
./get_input_files.sh


