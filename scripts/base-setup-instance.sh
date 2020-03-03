#!/bin/bash

# This script will setup the required system components, libraries
# and tools needed for ROMS forecast models on CentOS 7


setup_environment () {

  sudo mkdir /mnt/efs/fs1/save
  sudo mkdir /mnt/efs/fs1/com
  sudo mkdir /mnt/efs/fs1/ptmp

  sudo ln -s /mnt/efs/fs1/save /save
  sudo ln -s /mnt/efs/fs1/com /com
  sudo ln -s /mnt/efs/fs1/ptmp /ptmp

  sudo chgrp wheel /ptmp
  sudo chmod 775 /ptmp
  sudo chgrp -R wheel /com
  sudo chmod -R 775 /com
  sudo chgrp wheel /save 
  sudo chmod 775 /save

  sudo sed -i 's/tsflags=nodocs/# &/' /etc/yum.conf

  sudo yum -y install tcsh
  sudo yum -y install ksh
  sudo yum -y install wget
  sudo yum -y install glibc-devel
  sudo yum -y install zlib
  sudo yum -y install awscli
  sudo yum -y install vim-enhanced
  sudo yum -y install environment-modules

  echo . /usr/share/Modules/init/bash >> ~/.bashrc
  echo source /usr/share/Modules/init/tcsh >> ~/.tcshrc 
  . /usr/share/Modules/init/bash

  sudo mkdir -p /usrx/modulefiles
  echo /usrx/modulefiles | sudo tee -a ${MODULESHOME}/init/.modulespath
  echo . /usr/share/Modules/init/bash >> /etc/profile.d/custom.sh
  echo source /usr/share/Modules/init/csh >> /etc/profile.d/custom.csh
}






install_base_rpms () {

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
}



install_extra_rpms () {

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
}


install_efa_driver() {

  # version=latest
  version=1.8.3
  tarfile=aws-efa-installer-${version}.tar.gz

  wrkdir=~/efadriver
  [ -e $wrkdir ] && rm -Rf $wrkdir
  mkdir -p $wrkdir
  cd $wrkdir

  curl -O https://s3-us-west-2.amazonaws.com/aws-efa-installer/$tarfile
  tar -xvf $tarfile
  #rm $tarfile

  #cd aws-efa-installer
  # Install without AWS libfabric and OpenMPI, we will use Intel libfabric and MPI
  # This installer destroyed my system the first time!!!
  #sudo ./efa_installer.sh -y --minimal
}



install_ffmpeg () {
  echo "Stub"
 #https://ioos-cloud-sandbox/public/libs/ffmpeg-git-i686-static.tar.xz
}

 #mpi/intel/2020.0.154
install_impi () {

# 2019.6-154
# 2020.0.154
# /opt/intel/compilers_and_libraries/linux/mpi/intel64/modulefiles

  #sudo mkdir -p /usrx/modulefiles/mpi/intel
  #sudo cp -p /opt/intel/compilers_and_libraries/linux/mpi/intel64/modulefiles/mpi /usrx/modulefiles/mpi/intel/2020.0.154

  #wrkdir=/tmp/intel_mpi

  wrkdir=~/intel_mpi
  mkdir -p $wrkdir
  cd $wrkdir


  wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/intel_mpi_2019.5.281.tgz
  tar -xvf intel_mpi_2019.5.281.tgz

  echo 'Starting Intel MPI silent install... please wait'
  sudo ./install.sh -s silent.cfg 
  echo '... Finished impi silent install'

  sudo mkdir -p /usrx/modulefiles/mpi/intel
  sudo cp -p /opt/intel/compilers_and_libraries/linux/mpi/intel64/modulefiles/mpi /usrx/modulefiles/mpi/intel/2019.6.085

}



# Personal stuff here
setup_aliases () {

  echo alias lsl ls -al >> ~/.tcshrc
  echo alias lst ls -altr >> ~/.tcshrc
  echo alias h history >> ~/.tcshrc

  echo alias cds cd /save/$user >> ~/.tcshrc
  echo alias cdns cd /noscrub/$user >> ~/.tcshrc
  echo alias cdpt cd /ptmp/$user >> ~/.tcshrc


  git config --global user.name "Patrick Tripp"
  git config --global user.email patrick.tripp@rpsgroup.com

  #git commit --amend --reset-author
}

