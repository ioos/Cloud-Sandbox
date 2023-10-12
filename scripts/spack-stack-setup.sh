#!/bin/env bash

# Compilers - this includes environment module support
sudo yum -y install gcc-toolset-11-gcc-c++
sudo yum -y install gcc-toolset-11-gcc-gfortran
sudo yum -y install gcc-toolset-11-gdb


# Misc
sudo yum -y install m4
sudo yum -y install wget
sudo yum -y install git
sudo yum -y install git-lfs
sudo yum -y install bash-completion
sudo yum -y install bzip2 bzip2-devel
sudo yum -y install unzip
sudo yum -y install patch
sudo yum -y install automake
sudo yum -y install xorg-x11-xauth
sudo yum -y install xterm
sudo yum -y install texlive
sudo yum -y install mysql-server

# Do not install cmake (it's 3.20.2, which doesn't work with eckit)
# Do not install qt@5 for now

# For screen utility (optional)
#yum -y remove https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
#yum -y update --nobest
#yum -y install screen

# Python
sudo yum -y install python3.11-devel
sudo alternatives --set python3 /usr/bin/python3.11
sudo yum -y install python3.11-pip

# Install intel oneAPI compilers via yum

source scl_source enable gcc-toolset-11

cd /save/environments
git clone --recurse-submodules -b ioos-aws https://github.com/asascience/spack-stack.git
cd spack-stack
source setup.sh

#export SPACK_STACK_DIR
#echo "Setting environment variable SPACK_STACK_DIR to ${SPACK_STACK_DIR}"

#source ${SPACK_STACK_DIR}/spack/share/spack/setup-env.sh
#echo "Sourcing spack environment ${SPACK_STACK_DIR}/spack/share/spack/setup-env.sh"

# Creating a new site config
ENVNAME="ioos-aws-rhel"
spack stack create env --name $ENVNAME
cd envs/$ENVNAME/
spack env activate -p .

export SPACK_SYSTEM_CONFIG_PATH="$PWD"

spack external find --scope system --exclude bison --exclude cmake --exclude curl --exclude openssl --exclude openssh
spack external find --scope system perl
spack external find --scope system wget
spack external find --scope system mysql
spack external find --scope system texlive
cat >> packages.yaml <<EOL
  mysql:
    externals:
    - spec: mysql@8.0.32
      prefix: /usr
EOL

#source /opt/intel/oneapi/setvars.sh 
module use -a /save/environments/modulefiles

spack compiler find --scope system

unset SPACK_SYSTEM_CONFIG_PATH

spack add base-env arch=linux-rhel8-x86_64

# Need to manually fix the compilers.yaml file

cd $SPACK_STACK_DIR

spack concretize 2>&1 | tee log.concretize
util/show_duplicate_packages.py -d -c log.concretize
spack install --verbose --fail-fast

# Create tcl module files (replace tcl with lmod if you have manually installed lmod)

spack module tcl refresh
# Create meta-modules for compiler, mpi, python

spack stack setup-meta-modules

