# Source this file in script to use

export PREFECT_VER=3.6.29
export GCC_VER=14.3.1
export GCC_MAJOR=${GCC_VER%%.*}

export SPACK_VER='v1.2.0'

export ONEAPI_VER=2024.2.1
export ONEAPI_MAJOR_MINOR=${ONEAPI_VER%.*}

# The below versions correspond with ONEAPI_VER above
export INTEL_COMPILER_VER=2021.13.2
export INTEL_MPI_VER=2021.13

# intel oneapi version with RHEL 10 support 2025.x

# 2024.2 is the last one with ifort

# Upgrading INTEL_MPI for 2 EFA adaptors support, version 2021.12.0+
# MPI v 2021.12.0+ supports multiple EFA adaptors
# spack v0.22.3 and higher has that spec
# problems with spack v23

export ESMF_VER=8.9.1

# NOTE: Changing SPACK_DIR will still modify files in /etc/spack if using --scope system in spack commands
export SPACK_DIR="/save/environments/spack.${SPACK_VER}"

if [[ $(nproc) -eq 1 || $(nproc) -eq 2 ]]; then
    export JOBS=1
else
    export JOBS=$(($(nproc) - 1))
fi

#echo "PT DEBUG using single compile job"
#export JOBS=1

export SPACKOPTS="-v -y --jobs $JOBS --fail-fast"

#SPACKTARGET='target=skylake_avx512'         # default on skylake intel instances t3.xxxx
#SPACKTARGET='target=haswell'                # works on AMD also - has no avx512 extensions

# Generic
export target=x86_64_v3    # supports 3rd Gen AMD EPYC - hpc6a - Build First
# export target=x86_64_v4    # supports 4th and 5th Gen AMD EPYC AVX-512, hpc7a, hpc8a - Build and Benchmark later

# Best for AMD
# target=zen3         # hpc6a
# target=zen4         # hpc7a AVX-512
# target=zen5         # hpc8a AVX-512

export SPACKTARGET="arch=linux-rhel10-$target"

export EFA_INSTALLER_VER='1.48.0'
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa-changelog.html

#  1 = Don't build any packages. Only install packages from binary mirrors
#  0 = Will build if not found in mirror/cache
# -1 = Don't check pre-built binary cache

#export SPACK_CACHEONLY=0
#export SPACK_CACHEONLY=1
export SPACK_CACHEONLY=-1

if [ $SPACK_CACHEONLY -eq 1 ]; then
    echo "NOTICE: SPACK_CACHEONLY is set to 1 in environment-vars.sh"
    echo "NOTICE: Spack will only install if the precompiled package is found in the s3 mirror."
    echo "NOTICE: Spack will not build any packages."
    echo "NOTICE: Set SPACK_CACHEONLY=0 to enable building"
fi

# PT: TODO - move mirror to s3://ioos-sandbox-use2
export SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'
export SPACK_KEY_URL='https://ioos-cloud-sandbox.s3.amazonaws.com/public/spack/mirror/spack.mirror.gpgkey.pub'
export SPACK_KEY=${SPACK_DIR}/opt/spack/gpg/spack.mirror.gpgkey.pub

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

