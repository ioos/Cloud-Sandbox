#!/bin/bash

# This script will setup the required system components, libraries
# and tools needed for ROMS forecast models on CentOS 7


setup_environment () {

  sudo mkdir -p /ptmp 
  sudo chgrp wheel /ptmp
  sudo  chmod 775 /ptmp
  sudo mkdir -p /noscrub/com/nos 
  sudo chgrp -R wheel /noscrub 
  sudo chmod -R g+w /noscrub
  sudo mkdir -p /save 
  sudo chgrp wheel /save 
  sudo chmod 775 /save
  sudo sed -i 's/tsflags=nodocs/# &/' /etc/yum.conf

  sudo yum -y install tcsh
  sudo yum -y install ksh
  sudo yum -y install wget
  sudo yum -y install glibc-devel
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




install_libs () {

  #wrkdir=/tmp/rpms
  wrkdir=~/rpms
  mkdir -p $wrkdir
  cd $wrkdir

  wget https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/nosofs_base_rpms.gcc.6.5.0.el7.20191011.tgz

  tar -xvf nosofs_base_rpms.gcc.6.5.0.el7.20191011.tgz
  sudo yum -y install                 \
    gcc-6.5.0-1.el7.x86_64.rpm        \
    hdf5-1.8.21-1.el7.x86_64.rpm      \
    netcdf-4.2-1.el7.x86_64.rpm       \
    produtil-1.0.18-1.el7.x86_64.rpm

# 2019.6-154
# 2020.0.154
# /opt/intel/compilers_and_libraries/linux/mpi/intel64/modulefiles

sudo mkdir -p /usrx/modulefiles/mpi/intel
  sudo cp -p /opt/intel/compilers_and_libraries/linux/mpi/intel64/modulefiles/mpi /usrx/modulefiles/mpi/intel/2020.0.154

}



install_impi () {

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

