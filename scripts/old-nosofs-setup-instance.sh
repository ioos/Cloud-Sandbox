#!/bin/sh

# This script will setup the required system components, libraries
# and tools needed for nosofs/ROMS forecast models on RHEL 7 systems.

# --assumeyes -y

sudo yum -y install tcsh
sudo yum -y install ksh
sudo yum -y install wget

# Personal aliases here
echo alias lsl ls -al >> ~/.tcshrc
echo alias lst ls -altr >> ~/.tcshrc
echo alias h history >> ~/.tcshrc

echo alias cds cd /save/$user >> ~/.tcshrc
echo alias cdpt cd /ptmp/$user >> ~/.tcshrc

sudo yum -y install vim-enhanced
sudo yum -y groupinstall "Development Tools"
#sudo yum -y install gcc-gfortran
sudo yum -y erase gcc

# sudo yum -y install compat-libgfortran-48 # not needed now
# sudo yum -y install python2 # is already included in RHEL7
sudo yum -y install environment-modules

echo . /usr/share/Modules/init/bash >> ~/.bashrc
echo source /usr/share/Modules/init/tcsh >> ~/.tcshrc 
. /usr/share/Modules/init/sh

sudo mkdir -p /usrx/modulefiles
echo /usrx/modulefiles | sudo tee -a ${MODULESHOME}/init/.modulespath

cd RPMS
sudo rpm --install gcc-6.5.0-1.el7.x86_64.rpm

# Or use sudo yum -y install <package name with no .rpm extension>
sudo rpm --install zlib-1.2.11-1.el7.x86_64.rpm
sudo rpm --install jasper-1.900.1-1.el7.x86_64.rpm
# Install in different location than the RH included version
sudo rpm --install --force libpng-1.5.30-1.el7.x86_64.rpm
sudo rpm --install hdf5-1.8.21-1.el7.x86_64.rpm
sudo rpm --install bacio-v2.1.0-1.el7.x86_64.rpm
sudo rpm --install bufr-v11.0.2-1.el7.x86_64.rpm
sudo rpm --install g2-v3.1.0-1.el7.x86_64.rpm
sudo rpm --install nemsio-v2.2.4-1.el7.x86_64.rpm
sudo rpm --install sigio-v2.1.0-1.el7.x86_64.rpm
sudo rpm --install w3emc-v2.2.0-1.el7.x86_64.rpm
sudo rpm --install w3nco-v2.0.6-1.el7.x86_64.rpm
sudo rpm --install produtil-1.0.18-1.el7.x86_64.rpm
sudo rpm --install netcdf-4.2-1.el7.x86_64.rpm 
sudo rpm --install wgrib2-2.0.8-1.el7.x86_64.rpm

cd ..

# This only works for RedHat and Amazon Linux, didn't work with CentOS
#sudo yum-config-manager --add-repo https://yum.repos.intel.com/mpi/setup/intel-mpi.repo
#sudo rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS-2018.PUB
#sudo yum -y install intel-mpi-2018.4-057

ipkgver=2018.5.288
impiver=2018.6.288
cd intel_mpi_$ipkgver
sudo ./install.sh -s silent.cfg

sudo mkdir -p /usrx/modulefiles/mpi/intel
sudo cp -p /opt/intel/compilers_and_libraries_$impiver/linux/mpi/intel64/modulefiles/mpi /usrx/modulefiles/mpi/intel/$impiver


# The above sets up the environment for NCO operational NOSOFS ROMS models.
# It has been tested with CBOFS.

# Additional volumes should be added to hold your model source code, run scripts, and model output.
# Volume 1: source code and scripts. Suggested mount point of /save
# Volume 2: Forcing data, initial conditions, temporary run directories, and model output.
#           Suggest mounting at /noscrub.
# "save" and "noscrub" is a convention used on NCEP WCOSS systems. Where "save" directories 
# are backed up and contain important work such as source code and scripts. And "noscrub" contains
# data that is not backed up, is often large, and can be recreated or obtained elsewhere.
# Another convention and yet another volume that can be mounted is a scratch disk that is used as
# /ptmp or /stmp. These disks are automatically scrubbed (cleaned) on NCEP clusters and 

# For now, these are setup on the root / filesystem. 
# Will eventually need to set this up on a volume that is shared accross nodes

sudo mkdir -p /ptmp 
sudo chgrp wheel /ptmp
sudo chmod 775 /ptmp
mkdir /ptmp/$user

sudo mkdir -p /noscrub
sudo chgrp wheel /noscrub
sudo chmod 775 /noscrub
mkdir /noscrub/$user

sudo mkdir /save
sudo chgrp wheel /save
sudo chmod 775 /save
mkdir /save/$user
