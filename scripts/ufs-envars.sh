# Source this file in script to use

export GCC_VER=13.3.1

export ONEAPI_VER=2024.2.1
# The ONEAPI_VER above ^^^^ installs the INTEL_COMPILER_VERSION below vvvv
export INTEL_COMPILER_VER=2021.13.1

####
export INTEL_MPI_VER=2021.16.0
export ESMF_VER=8.5.0
export SPACK_VER='v0.22.5'
# NOTE: Changing SPACK_DIR will still modify files in /etc/spack if using --scope system in spack commands
export SPACK_DIR="/save/environments/spack.${SPACK_VER}"
####

export SPACKSTACK_VER=2.0
export SPACKSTACK_DIR="/save/environments/spack-stack.v${SPACKSTACK_VER}"

#SPACKOPTS='-v -y --dirty'   # don't rememeber why I needed --dirty, everything built fine without it, maybe esmf needs it?
export SPACKOPTS='-v -y'

#SPACKTARGET='target=skylake_avx512'         # default on skylake intel instances t3.xxxx
#SPACKTARGET='target=haswell'                # works on AMD also - has no avx512 extensions
#SPACKTARGET='target=x86_64'                 # works on AMD and Intel x86_64
export SPACKTARGET="arch=linux-rhel8-x86_64_v3"

export EFA_INSTALLER_VER='1.38.0'
# PT DO: bump this to newer version, e.g. 1.48.0 
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa-changelog.html

#  1 = Don't build any packages. Only install packages from binary mirrors
#  0 = Will build if not found in mirror/cache
# -1 = Don't check pre-built binary cache

#export SPACK_CACHEONLY=0
export SPACK_CACHEONLY=1
#export SPACK_CACHEONLY=-1

if [ $SPACK_CACHEONLY -eq 1 ]; then
    echo "NOTE: SPACK_CACHEONLY is set to 1 in environment-vars.sh"
    echo "NOTE: Spack will only install if the precompiled package is found in the s3 mirror."
    echo "NOTE: Spack will not build any packages."
    echo "NOTE: Set SPACK_CACHEONLY=0 to enable building"
fi

# s3://ioos-sandbox-use2/public/spack-stack/mirror/
export SPACK_MIRROR='s3://ioos-sandbox-use2/public/spack-stack/mirror'
export SPACK_KEY='spack.mirror.gpgkey.pub'
export SPACK_KEY_URL="https://ioos-sandbox-use2.s3.amazonaws.com/public/spack-stack/mirror/$SPACK_KEY"


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
export ami_name=${ami_name:="IOOS-Cloud-Sandbox-${now}"}
export project_tag=${project_tag:="IOOS-Cloud-Sandbox"}

