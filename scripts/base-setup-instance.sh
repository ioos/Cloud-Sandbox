#!/bin/bash

# This script will setup the required system components, libraries
# and tools needed for ROMS forecast models on CentOS 7

#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

setup_environment () {

  home=$PWD

  cd /mnt/efs/fs1

  sudo mkdir ptmp
  sudo mkdir com
  sudo mkdir save

  sudo chgrp wheel ptmp
  sudo chmod 775 ptmp
  sudo chgrp wheel com
  sudo chmod 775 com
  sudo chgrp wheel save 
  sudo chmod 775 save

  sudo ln -s /mnt/efs/fs1/ptmp /ptmp
  sudo ln -s /mnt/efs/fs1/com /com
  sudo ln -s /mnt/efs/fs1/save /save

  sudo sed -i 's/tsflags=nodocs/# &/' /etc/yum.conf

  sudo yum -y install tcsh
  sudo yum -y install ksh
  sudo yum -y install wget
  sudo yum -y install glibc-devel
  sudo yum -y install automake
  sudo yum -y install vim-enhanced
  sudo yum -y install environment-modules
  sudo yum -y install python3-devel
  sudo yum -y install awscli

  echo . /usr/share/Modules/init/bash >> ~/.bashrc
  echo source /usr/share/Modules/init/tcsh >> ~/.tcshrc 
  . /usr/share/Modules/init/bash

  sudo mkdir -p /usrx/modulefiles
  echo /usrx/modulefiles | sudo tee -a ${MODULESHOME}/init/.modulespath
  echo ". /usr/share/Modules/init/bash" | sudo tee -a /etc/profile.d/custom.sh
  echo "source /usr/share/Modules/init/csh" | sudo tee -a /etc/profile.d/custom.csh

  cd $home
}




install_efa_driver() {

  home=$PWD
 
  # This must be installed before the rest

  # version=latest
  version=1.8.3
  tarfile=aws-efa-installer-${version}.tar.gz

  wrkdir=~/efadriver
  [ -e $wrkdir ] && rm -Rf $wrkdir
  mkdir -p $wrkdir
  cd $wrkdir

  # If this exists, efa driver intall fails, move it
  sudo mkdir /usr/lib/oldkernel
  sudo mv /usr/lib/modules/3.10.0-957.1.3.el7.x86_64 /usr/lib/oldkernel

  # This will get upgraded when we install gcc 6.5
  # Default version is needed to build the kernel driver
  sudo yum -y install gcc

  curl -O https://s3-us-west-2.amazonaws.com/aws-efa-installer/$tarfile
  tar -xvf $tarfile
  rm $tarfile

  cd aws-efa-installer

  # Install without AWS libfabric and OpenMPI, we will use Intel libfabric and MPI
  sudo ./efa_installer.sh -y --minimal

  # Put this back in original location
  sudo mv /usr/lib/oldkernel/3.10.0-957.1.3.el7.x86_64  /usr/lib/modules
  sudo rmdir /usr/lib/oldkernel

  cd $home

}



install_base_rpms () {

  home=$PWD

  # gcc/6.5.0  hdf5/1.10.5  netcdf/4.5  produtil/1.0.18
  libstar=base_rpms.gcc.6.5.0.el7.20191212.tgz

  wrkdir=~/baserpms
  [ -e $wrkdir ] && rm -Rf $wrkdir
  mkdir -p $wrkdir
  cd $wrkdir

  wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/$libstar
  tar -xvf $libstar
  rm $libstar
  
  for file in `ls -1 *.rpm`
  do
    sudo yum -y install $file
  done

  rm -Rf $wrkdir

  cd $home
}



install_extra_rpms () {

  home=$PWD

  # bacio/v2.1.0         w3nco/v2.0.6
  # bufr/v11.0.2         libpng/1.5.30        wgrib2/2.0.8
  # g2/v3.1.0            sigio/v2.1.0
  # nemsio/v2.2.4        w3emc/v2.2.0 

  libstar=extra_rpms.el7.20191205.tgz

  wrkdir=~/extrarpms
  [ -e $wrkdir ] && rm -Rf $wrkdir
  mkdir -p $wrkdir
  cd $wrkdir

  wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/$libstar
  tar -xvf $libstar
  rm $libstar

  for file in `ls -1 *.rpm`
  do
    sudo yum -y install $file
  done

  # Force install newer libpng
  sudo rpm --install --force libpng-1.5.30-1.el7.x86_64.rpm  

  rm -Rf $wrkdir

  sudo yum -y install jasper-devel

  cd $home
}


install_python_modules_user () {

  home=$PWD

  . /usr/share/Modules/init/bash
  module load gcc
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
  [ -e $wrkdir ] && rm -Rf $wrkdir
  mkdir -p $wrkdir
  cd $wrkdir

  wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/$tarfile
  tar -xvf $tarfile
  rm $tarfile
 
  sudo mkdir -p /usrx/ffmpeg/$version
  sudo cp -Rp ffmpeg-git-${version}-i686-static/* /usrx/ffmpeg/$version

  sudo ln -sf /usrx/ffmpeg/${version}/ffmpeg /usr/local/bin

  rm -Rf $wrkdir

  cd $home
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

