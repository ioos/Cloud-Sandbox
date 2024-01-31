#!/bin/env bash

home=$PWD

# Compilers - this includes environment module support
#PT sudo yum -y install gcc-toolset-11-gcc-c++
#PT sudo yum -y install gcc-toolset-11-gcc-gfortran
#PT sudo yum -y install gcc-toolset-11-gdb

# Misc
#PT sudo yum -y install m4
#PT sudo yum -y install wget
#PT sudo yum -y install git
#PT sudo yum -y install git-lfs
#PT sudo yum -y install bash-completion
#PT sudo yum -y install bzip2 bzip2-devel
#PT sudo yum -y install unzip
#PT sudo yum -y install patch
#PT sudo yum -y install automake
#PT sudo yum -y install xorg-x11-xauth
#PT sudo yum -y install xterm
#PT sudo yum -y install texlive
#PT sudo yum -y install mysql-server

# Do not install cmake (it's 3.20.2, which doesn't work with eckit)
# Do not install qt@5 for now

# For screen utility (optional)
#yum -y remove https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
#yum -y update --nobest
#yum -y install screen

# Python
#PT sudo yum -y install python3.11-devel
#PT sudo alternatives --set python3 /usr/bin/python3.11
#PT sudo yum -y install python3.11-pip

# Install intel oneAPI compilers via yum - Tried that, didnt work so well

#PT source scl_source enable gcc-toolset-11

cd /save/environments
# git clone --recurse-submodules -b ioos-aws https://github.com/asascience/spack-stack.git
cd spack-stack
source setup.sh

#export SPACK_STACK_DIR
#echo "Setting environment variable SPACK_STACK_DIR to ${SPACK_STACK_DIR}"

#source ${SPACK_STACK_DIR}/spack/share/spack/setup-env.sh
#echo "Sourcing spack environment ${SPACK_STACK_DIR}/spack/share/spack/setup-env.sh"

# Creating a new site config
ENVNAME="ioos-aws-rhel8-x86-64"
#PT spack stack create env --name $ENVNAME
cd envs/$ENVNAME/
spack env activate -p .

#PT export SPACK_SYSTEM_CONFIG_PATH="$PWD"

#PT spack external find --scope system --exclude bison --exclude cmake --exclude curl --exclude openssl --exclude openssh
#PT spack external find --scope system perl
#PT spack external find --scope system wget
#PT spack external find --scope system mysql
#PT spack external find --scope system texlive
#PT cat >> packages.yaml <<EOL
#PT   mysql:
#PT     externals:
#PT     - spec: mysql@8.0.32
#PT       prefix: /usr
#PT EOL

#source /opt/intel/oneapi/setvars.sh 
# module use -a /save/environments/modulefiles

#PT spack compiler find --scope system

#PT unset SPACK_SYSTEM_CONFIG_PATH

#PT spack add intel-oneapi-compilers@2023.1.0
#PT spack add intel-oneapi-mpi@2021.9.0 %intel@2021.9.0 arch=linux-rhel8-x86_64

# Need to manually fix the compilers.yaml file

cd $SPACK_STACK_DIR

#PT spack concretize 2>&1 | tee log.concretize
#PT util/show_duplicate_packages.py -d -c log.concretize

#PT spack install --verbose --fail-fast

#PT spack compiler add `spack location -i intel-oneapi-compilers`/compiler/latest/linux/bin/intel64
#PT spack compiler add `spack location -i intel-oneapi-compilers`/compiler/latest/linux/bin

#PT spack module tcl refresh
#PT spack stack setup-meta-modules

# Add more packages and repeat

# spack add base-env arch=linux-rhel8-x86_64

exit

# Create meta-modules for compiler, mpi, python

