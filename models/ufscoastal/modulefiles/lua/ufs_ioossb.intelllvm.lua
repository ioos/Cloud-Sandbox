help([[
loads UFS Model prerequisites for AWS IOOS Cloud Sandbox
]])

prepend_path("MODULEPATH", "/save/environments/spack-stack.v2.1.0/envs/aws-ioossb-rhel10/modules/Core")
prepend_path("MODULEPATH", "/save/environments/spack-stack.v2.1.0/envs/aws-ioossb-rhel10/modules/intel-oneapi-mpi/2021.16/intel-oneapi-compilers/2024.2.1/impi/2021.16/oneapi/2024.2.1")
prepend_path("MODULEPATH", "/save/environments/spack-stack.v2.1.0/envs/aws-ioossb-rhel10/modules/intel-oneapi-mpi/2021.16/intel-oneapi-compilers/2024.2.1")
prepend_path("MODULEPATH", "/save/environments/spack-stack.v2.1.0/envs/aws-ioossb-rhel10/modules/intel-oneapi-compilers/2024.2.1/oneapi/2024.2.1")

load("stack-intel-oneapi-compilers/2024.2.1")
load("intel/compiler/2024.2.1")
load("intel/mpi/2021.16")
load("intel/mkl/2024.2")
load("netcdf-c/4.9.2")
load("netcdf-fortran/4.6.1")
load("parmetis/4.0.3")
load("esmf/8.8.0")
load("oneapi/2024.2.1/sp/2.5.0")

load("bacio/2.6.0")
load("w3emc/2.13.0")
load("metis/5.1.0")

setenv("PARMETIS_HOME","/save/environments/spack-stack.v2.1.0/envs/aws-ioossb-rhel10/install/__spack_p/intel-oneapi-compilers/2024.2.1/parmetis-4.0.3-54vlb4m")
setenv("METIS_PATH","/mnt/efs/fs1/save/environments/spack-stack.v2.1.0/envs/aws-ioossb-rhel10/install/__spack_p/intel-oneapi-compilers/2024.2.1/metis-5.1.0-pk2iwyn")

-- -- 1. Instruct Lmod to load your dependency
-- load("some-module")
-- 
-- 2. Determine what mode Lmod is operating in
-- if (mode() == "load") then
--     -- Now that 'some-module' is loaded, CPATH contains the target path. 
--     -- Grab it and assign it to your custom variable name:
--     local target_path = os.getenv("CPATH") or ""
--     setenv("SOME_Envar", target_path)
--end

-- udunits/2.2.28
-- libpng/1.6.37
-- jasper/4.2.4
-- ip/5.4.0
-- g2/3.5.1
--load("zlib/1.2.13")

setenv("CC", "mpiicx")
setenv("CXX", "mpiicpx")
setenv("FC", "mpiifx")

setenv("I_MPI_CC", "icx")
setenv("I_MPI_CXX","icpx")
setenv("I_MPI_FC", "ifx")

setenv("CMAKE_Platform", "ioossb.intelllvm")

whatis("Description: UFS build environment")
