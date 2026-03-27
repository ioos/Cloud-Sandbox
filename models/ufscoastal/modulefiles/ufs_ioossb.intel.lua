help([[
loads UFS Model prerequisites for AWS IOOS Cloud Sandbox
]])

--prepend_path("MODULEPATH", "/apps/contrib/spack-stack/spack-stack-1.9.2/envs/ue-oneapi-2024.1.0/install/modulefiles/Core")
prepend_path("MODULEPATH", "/save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8/modules/Core")
--prepend_path("MODULEPATH", "/apps/contrib/spack-stack/spack-stack-1.9.2/envs/ue-oneapi-2024.1.0/install/modulefiles/intel-oneapi-mpi/2021.13-sqiixt7/gcc/13.3.0")
--prepend_path("MODULEPATH", "/save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8/modules/ ") --not sure


--stack_intel_ver=os.getenv("stack_intel_ver") or "2024.2.1"
--stack-intel-oneapi-compilers/2024.2.1
--load(pathJoin("stack-intel-oneapi-compilers", stack_intel_ver))

load("stack-intel-oneapi-compilers/2024.2.1")
load("intel-oneapi-compilers/2024.2.1")


--stack_impi_ver=os.getenv("stack_impi_ver") or "2021.13"
--load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))

--cmake_ver=os.getenv("cmake_ver") or "3.27.9"
--load(pathJoin("cmake", cmake_ver))


--load("ufs_common")
--
--intel-oneapi-mpi/2021.13.0/intel-oneapi-compilers/2024.2.1/impi/2021.13.0/oneapi/2024.2.1/scotch/7.0.10
--./intel-oneapi-mpi/2021.13.0/intel-oneapi-compilers/2024.2.1/impi/2021.13.0/oneapi/2024.2.1/scotch
--
--load("zlib/1.2.13")

--nccmp_ver=os.getenv("nccmp_ver") or "1.9.0.1"
--load(pathJoin("nccmp", nccmp_ver))

setenv("CC", "mpiicc")
setenv("CXX", "mpiicpc")
setenv("FC", "mpiifort")
setenv("CMAKE_Platform", "aws-ioossb.intel")

whatis("Description: UFS build environment")
