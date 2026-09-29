#%Module
#
proc ModulesHelp { } {
puts stderr "tcl modulefile for ufs"
}

module-whatis "This module sets the environment for ufs coastal app"

module use -a /save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8/modulefiles.tcl/Core

module load stack-intel-oneapi-compilers/2024.2.1
module load stack-intel-oneapi-mpi/2021.13.0
module load intel-oneapi-mpi/2021.13.0
module load intel-oneapi-mkl/2024.2.2
#
#cmake_ver=os.getenv("cmake_ver") or "3.27.9"
#load(pathJoin("cmake", cmake_ver))
#
#load("zlib/1.2.13")
#
#nccmp_ver=os.getenv("nccmp_ver") or "1.9.0.1"
#load(pathJoin("nccmp", nccmp_ver))

# module load ufs-weather-model-env/1.0.0

#load("ufs_common")
# UFS Common
module load jasper/4.2.4
module load libpng//1.6.37
module load netcdf-fortran/4.6.1
module load netcdf-c/4.9.2
module load hdf5/1.14.5
module load parallelio/2.6.2
module load parallel-netcdf/1.12.3
module load esmf/8.8.0
module load fms/2024.02-gfs-constants
module load bacio/2.6.0
module load crtm/3.1.2
module load g2/3.5.1
module load g2tmpl/1.17.0
module load ip/5.4.0

# WHO NAMES A PACKAGE "ip" or "sp"!? Very difficult to search for and debug
# It looks like sp was never built. It is not in the build cache.
# The package does appear in the the common/packages.yaml file though.
# This is the ncep-libs splib spectral transform library 
# It might not be needed for ufs-coastal-app - will test the build
#  {["ip"]          = "4.0.0"},
module load sp/2.5.0
#  {["sp"]          = "2.3.3"},
#
module load w3emc/2.11.0
module load gftl-shared/1.11.0
module load mapl/2.53.4-esmf-8.8.0
module load scotch/7.0.10 

#setenv("CC", "mpiicc")
#setenv("CXX", "mpiicpc")
#setenv("FC", "mpiifort")
#setenv("CMAKE_Platform", "ioossb.intel")

setenv CC "mpiicc"
setenv CXX "mpiicpc"
setenv FC "mpiifort"

setenv I_MPI_CC "icx"
setenv I_MPI_CXX "icpx"
setenv I_MPI_F90 "ifort"

#setenv("I_MPI_CC", "icx")
# setenv("I_MPI_CXX", "icpx")
# setenv("I_MPI_F90", "ifx")
setenv CMAKE_Platform "ioossb.intel"


