# Source this file in script to use

GCC_VER=11.2.1

# Current used versions
ONEAPI_VER=2023.1.0
# The ONEAPI_VER above ^^^^ installs the INTEL_COMPILER_VERSION below vvvv
INTEL_COMPILER_VER=2021.9.0

# Upgrading INTEL_MPI for 2 EFA adaptors support, version 2021.12.0+
# MPI v 2021.12.0+ supports multiple EFA adaptors
# spack v0.22.3 and higher has that spec
# problems with spack v23

INTEL_MPI_VER=2021.12.1

ESMF_VER=8.5.0

SPACK_VER='v0.22.5'

SPACK_DIR='/save/environments/spack'
SPACKOPTS='-v -y'

#SPACKTARGET='target=skylake_avx512'         # default on skylake intel instances t3.xxxx
#SPACKTARGET='target=haswell'                # works on AMD also - has no avx512 extensions
#SPACKTARGET='target=x86_64'                 # works on AMD and Intel x86_64
SPACKTARGET="arch=linux-rhel8-x86_64"

EFA_INSTALLER_VER='1.38.0'

#  1 = Don't build any packages. Only install packages from binary mirrors
#  0 = Will build if not found in mirror/cache
# -1 = Don't check pre-built binary cache

SPACK_CACHEONLY=0

SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'

#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# !! ami_names must be unique
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------

# ami_name is provided by Terraform if called via the init_template
# otherwise it will use the default

now=`date -u +\%Y\%m\%d_\%H-\%M`
ami_name=${ami_name:="${now}-IOOS-Cloud-Sandbox"}
project_tag=${project_tag:="IOOS-Cloud-Sandbox"}

