#!/bin/bash

# This script will setup the required system components, libraries
# and tools needed for ROMS forecast models on CentOS 7

#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

setup_environment () {

  home=$PWD

  # By default, centos 7 does not install the docs (man pages) for packages, remove that setting here
  sudo sed -i 's/tsflags=nodocs/# &/' /etc/yum.conf

  sudo yum -y update
  sudo yum -y install epel-release
  sudo yum -y install tcsh
  sudo yum -y install ksh
  sudo yum -y install wget
  sudo yum -y install time.x86_64
  sudo yum -y install glibc-devel
  sudo yum -y install automake
  sudo yum -y install vim-enhanced
  sudo yum -y install environment-modules
  sudo yum -y install python3-devel
  sudo yum -y install awscli

  # Only do this once
  grep "/usr/share/Modules/init/bash" ~/.bashrc >& /dev/null
  if [ $? -eq 1 ] ; then
    echo . /usr/share/Modules/init/bash >> ~/.bashrc
    echo source /usr/share/Modules/init/tcsh >> ~/.tcshrc 
    . /usr/share/Modules/init/bash
  fi

  # Only do this once
  if [ ! -d /usrx/modulefiles ] ; then
    sudo mkdir -p /usrx/modulefiles
    echo /usrx/modulefiles | sudo tee -a ${MODULESHOME}/init/.modulespath
    echo ". /usr/share/Modules/init/bash" | sudo tee -a /etc/profile.d/custom.sh
    echo "source /usr/share/Modules/init/csh" | sudo tee -a /etc/profile.d/custom.csh
  fi
}


setup_paths () {

  home=$PWD

  if [ ! -d /mnt/efs/fs1 ]; then
    echo "ERROR: EFS disk is not mounted"
    exit 1
  fi

  cd /mnt/efs/fs1
  if [ ! -d ptmp ] ; then
    sudo mkdir ptmp
    sudo mkdir com
    sudo mkdir save

    sudo chgrp wheel ptmp
    sudo chmod 775 ptmp
    sudo chgrp wheel com
    sudo chmod 775 com
    sudo chgrp wheel save
    sudo chmod 775 save
  fi

  sudo ln -s /mnt/efs/fs1/ptmp /ptmp
  sudo ln -s /mnt/efs/fs1/com  /com
  sudo ln -s /mnt/efs/fs1/save /save

  cd $home
}


setup_environment_osx () {
  cd ~/.ssh
  cat id_rsa.pub >> authorized_keys
}


install_efa_driver() {

# This must be installed before the rest

# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa-start.html

# Note this error:
# No package kernel-devel-3.10.0-1062.12.1.el7.x86_64 available.
# Error: Not tolerating missing names on install, stopping.
# Error: Failed to install packages.
# 
# ==============================================================================
# The kernel header of the current kernel version cannot be installed and is required
# to build the EFA kernel module. Please install the kernel header package for your
# distribution manually or build the EFA kernel driver manually and re-run the installer
# with --skip-kmod.
# ==============================================================================
#
# The kernel version might have been updated since last reboot, if so, reboot the machine, and rerun this step.
# To see the current running kernel:
# uname -a
#
# Available kernels are visible
# at /usr/lib/modules
# 3.10.0-1160.24.1.el7.x86_64

  home=$PWD

  version=latest
  #version=1.11.2 (April 20, 2021)
  #version=1.8.3
  tarfile=aws-efa-installer-${version}.tar.gz

  wrkdir=~/efadriver
  [ -e "$wrkdir" ] && rm -Rf "$wrkdir"
  mkdir -p "$wrkdir"
  cd "$wrkdir"

  # There may be old kernels laying around without available headers, temporarily move them
  # otherwise the efa driver might fail

  sudo mkdir /usr/lib/oldkernel
  while [ `ls -1 /usr/lib/modules | wc -l` -gt 1 ]
  do
    oldkrnl=`ls -1 /usr/lib/modules | head -1`
    sudo mv /usr/lib/modules/$oldkrnl /usr/lib/oldkernel
  done

  # This will get upgraded when we install gcc 6.5
  # Default version is needed to build the kernel driver
  # If gcc has already been upgraded, this will likely fail
  # Should uninstall newer one and install the default 4.8
  sudo yum -y install gcc

  curl -O https://s3-us-west-2.amazonaws.com/aws-efa-installer/$tarfile
  tar -xvf $tarfile
  rm $tarfile

  cd aws-efa-installer

  # Install without AWS libfabric and OpenMPI, we will use Intel libfabric and MPI
  sudo ./efa_installer.sh -y --minimal

  # Put old kernels back in original location
  sudo mv /usr/lib/oldkernel/*  /usr/lib/modules
  sudo rmdir /usr/lib/oldkernel

  cd $home
}



install_base_rpms () {

  home=$PWD

  # gcc/6.5.0  hdf5/1.10.5  netcdf/4.5  produtil/1.0.18 esmf/8.0.0
  libstar=base_rpms.gcc.6.5.0.el7.20200716.tgz

  wrkdir=~/baserpms
  [ -e "$wrkdir" ] && rm -Rf "$wrkdir"
  mkdir -p "$wrkdir"
  cd "$wrkdir"

  wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/$libstar
  tar -xvf $libstar
  rm $libstar
 
  # GCC needs to be installed first
  rpmlist='
    gcc-6.5.0-1.el7.x86_64.rpm
    hdf5-1.10.5-4.el7.x86_64.rpm
    netcdf-4.5-3.el7.x86_64.rpm
    esmf-8.0.0-1.el7.x86_64.rpm
    produtil-1.0.18-2.el7.x86_64.rpm
  '
 
  for file in $rpmlist
  do
    sudo yum -y install $file
  done

  rm -Rf "$wrkdir"

  cd $home
}



install_extra_rpms () {

  home=$PWD

  # bacio/v2.1.0         w3nco/v2.0.6
  # bufr/v11.0.2         libpng/1.5.30        wgrib2/2.0.8
  # g2/v3.1.0            sigio/v2.1.0
  # nemsio/v2.2.4        w3emc/v2.2.0 

  libstar=extra_rpms.el7.20200716.tgz

  rpmlist=' 
    bacio-v2.1.0-1.el7.x86_64.rpm
    bufr-v11.0.2-1.el7.x86_64.rpm
    g2-v3.1.0-1.el7.x86_64.rpm
    nemsio-v2.2.4-1.el7.x86_64.rpm
    sigio-v2.1.0-1.el7.x86_64.rpm
    w3emc-v2.2.0-1.el7.x86_64.rpm
    w3nco-v2.0.6-1.el7.x86_64.rpm
    wgrib2-2.0.8-2.el7.x86_64.rpm
  '

  wrkdir=~/extrarpms
  [ -e "$wrkdir" ] && rm -Rf "$wrkdir"
  mkdir -p "$wrkdir"
  cd "$wrkdir"

  wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/$libstar
  tar -xvf $libstar
  rm $libstar

  for file in $rpmlist
  do
    sudo yum -y install $file
  done

  # Force install newer libpng leaving the existing one intact
  # this one will be used for our model builds
  sudo rpm -v --install --force libpng-1.5.30-2.el7.x86_64.rpm  

  rm -Rf "$wrkdir"

  sudo yum -y install jasper-devel

  cd $home
}


install_python_modules_user () {

  home=$PWD

  . /usr/share/Modules/init/bash
  module load gcc
  sudo python3 -m pip install --upgrade pip
  python3 -m pip install --user wheel
  python3 -m pip install --user dask distributed
  python3 -m pip install --user setuptools_rust  # needed for paramiko
  python3 -m pip install --user paramiko   # needed for dask-ssh
  python3 -m pip install --user prefect
  python3 -m pip install --user boto3


  exit
  # Build and install the plotting module
  # This will also install dependencies
  cd ../..
  # Should be in ~/Cloud-Sandbox/cloudflow
  pwd
  python3 ./setup.py sdist
  python3 -m pip install --user dist/plotting-*.tar.gz
 
  cd $home 
}


install_python_modules_osx () {

  home=$PWD

  pip3 install --user dask distributed
  pip3 install --user paramiko   # needed for dask-ssh
  pip3 install --user prefect
  pip3 install --user boto3


  # Build and install the plotting module
  # This will also install dependencies
  cd ../workflow
  python3 ./setup.py sdist
  pip3 install --user dist/plotting-*.tar.gz

  cd $home
}



install_ffmpeg () {
  home=$PWD

  version=20200127
  tarfile=ffmpeg-git-i686-static.tar.xz

  wrkdir=~/ffmpeg
  [ -e "$wrkdir" ] && rm -Rf "$wrkdir"
  mkdir -p "$wrkdir"
  cd "$wrkdir"

  wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/$tarfile
  tar -xvf $tarfile
  rm $tarfile
 
  sudo mkdir -p /usrx/ffmpeg/$version
  sudo cp -Rp ffmpeg-git-${version}-i686-static/* /usrx/ffmpeg/$version

  sudo ln -sf /usrx/ffmpeg/${version}/ffmpeg /usr/local/bin

  rm -Rf "$wrkdir"

  cd $home
}

install_ffmpeg_osx () {

  which brew > /dev/null
  if [ $? -ne 0 ] ; then
    echo "Homebrew is missing ... install Homebrew then retry ... exiting"
    exit 1
  fi

  brew install ffmpeg
}



install_impi () {

  home=$PWD

  sudo ./aws_impi.sh install -check_efa 0

  version=`cat /opt/intel/compilers_and_libraries/linux/mpi/intel64/modulefiles/mpi | grep " topdir" | awk '{print $3}' | awk -F_ '{print $4}'`

  sudo mkdir -p /usrx/modulefiles/mpi/intel
  sudo cp -p /opt/intel/compilers_and_libraries/linux/mpi/intel64/modulefiles/mpi /usrx/modulefiles/mpi/intel/$version

  cd $home
}



# Personal stuff here
setup_aliases () {

  home=$PWD

  echo alias lsl ls -al >> ~/.tcshrc
  echo alias lst ls -altr >> ~/.tcshrc
  echo alias h history >> ~/.tcshrc

  echo alias cds cd /save/$user >> ~/.tcshrc
  echo alias cdns cd /noscrub/$user >> ~/.tcshrc
  echo alias cdpt cd /ptmp/$user >> ~/.tcshrc


  git config --global user.name "Patrick Tripp"
  git config --global user.email patrick.tripp@rpsgroup.com

  #git commit --amend --reset-author

  cd $home
}

