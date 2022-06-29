
GCC_VER=8.5.0
INTEL_VER=2021.3.0

SPACK_VER='releases/v0.18'
SPACK_DIR='/save/environments/spack'
SPACKOPTS='-v -y'

#HDF5_VER='1.13.1'
# HDF5_VER='1.12.2'
SLURM_VER='22-05-2-1'
#SLURM_VER='21-08-8-2'  # doesn't build

#  1 = Don't build any packages. Only install packages from binary mirrors
#  0 = Will build if not found in mirror/cache
# -1 = Don't check pre-built binary cache

SPACK_CACHEONLY=0

if [ $SPACK_CACHEONLY -eq 1 ]; then
  SPACKOPTS="$SPACKOPS --cache-only"
elif [ $SPACK_CACHEONLY -eq -1 ]; then
  SPACKOPTS="$SPACKOPS --no-cache"
fi

# This script will setup the required system components, libraries
# and tools needed for ROMS forecast models on CentOS 7

#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"


setup_environment () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  # By default, centos 7 does not install the docs (man pages) for packages, remove that setting here
  sudo sed -i 's/tsflags=nodocs/# &/' /etc/yum.conf

  # yum update might update the kernel. 
  # This might cause some of the other installs to fail, e.g. efa driver 

  #sudo yum -y update
  sudo yum -y install epel-release
  sudo yum -y install tcsh
  sudo yum -y install ksh
  sudo yum -y install wget
  sudo yum -y install unzip
  sudo yum -y install time.x86_64
  sudo yum -y install glibc-devel
  sudo yum -y install gcc-c++
  sudo yum -y install patch
  sudo yum -y install bzip2
  sudo yum -y install bzip2-devel
  sudo yum -y install automake
  sudo yum -y install vim-enhanced
  sudo yum -y install environment-modules
  sudo yum -y install python3-devel
  sudo yum -y install jq

  cliver="2.2.10"
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${cliver}.zip" -o "awscliv2.zip"
  /usr/bin/unzip -q awscliv2.zip
  sudo ./aws/install
  rm awscliv2.zip
  rm -Rf "./aws"

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

  echo "Running ${FUNCNAME[0]} ..."

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
    sudo chmod 777 ptmp
    sudo chgrp wheel com
    sudo chmod 777 com
    sudo chgrp wheel save
    sudo chmod 777 save
  fi

  sudo ln -s /mnt/efs/fs1/ptmp /ptmp
  sudo ln -s /mnt/efs/fs1/com  /com
  sudo ln -s /mnt/efs/fs1/save /save

  cd $home
}


#-----------------------------------------------------------------------------#

setup_environment_osx () {
  cd ~/.ssh
  cat id_rsa.pub >> authorized_keys
}

#-----------------------------------------------------------------------------#

install_efa_driver() {

  echo "Running ${FUNCNAME[0]} ..."

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
# Available kernels are visible at /usr/lib/modules
#
# The AWS centos 7 is still at version 1062 and has to be updated and rebooted before this will work
# since the standard yum registry only has the current 1160 kernel-devel package
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

  # Default version is needed to build the kernel driver
  # If gcc has already been upgraded, this will likely fail
  # Should uninstall newer one and install the default 4.8
  # sudo yum -y install gcc

  curl -s -O https://s3-us-west-2.amazonaws.com/aws-efa-installer/$tarfile
  tar -xf $tarfile
  rm $tarfile

  cd aws-efa-installer

  # Install without AWS libfabric and OpenMPI, we will use Intel libfabric and MPI
  sudo ./efa_installer.sh -y 

  # Put old kernels back in original location
  if [ $(ls /usr/lib/oldkernel/ | wc -l) -ne 0 ]; then
    sudo mv /usr/lib/oldkernel/*  /usr/lib/modules
    sudo rmdir /usr/lib/oldkernel
  fi

  cd $home
}

#-----------------------------------------------------------------------------#

install_spack() {

  echo "Running ${FUNCNAME[0]} ..."
  home=$PWD

  SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'
  SPACK_KEY_URL='https://ioos-cloud-sandbox.s3.amazonaws.com/public/spack/mirror/spack.mirror.gpgkey.pub'
  SPACK_KEY="$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.pub"

  echo "Installing SPACK in $SPACK_DIR ..."

  if [ ! -d /save ] ; then
    echo "/save does not exst. Setup the paths first."
    return
  fi

  mkdir -p $SPACK_DIR
  git clone -q https://github.com/spack/spack.git $SPACK_DIR
  cd $SPACK_DIR
  git checkout -q $SPACK_VER
  echo ". $SPACK_DIR/share/spack/setup-env.sh" >> ~/.bashrc
  echo "source $SPACK_DIR/share/spack/setup-env.csh" >> ~/.tcshrc 

  # Location for overriding default configurations
  sudo mkdir /etc/spack
 
  . $SPACK_DIR/share/spack/setup-env.sh

  # TODO: Rebuild everything using this, and push to mirror
  # spack config add "config:install_tree:padded_length:128"

  # Using an s3-mirror for previously built packages
  echo "Using SPACK s3-mirror $SPACK_MIRROR"
  spack mirror add s3-mirror $SPACK_MIRROR

  spack buildcache keys --install --trust --force
  spack buildcache update-index -d $SPACK_MIRROR

  cd $home
}

#-----------------------------------------------------------------------------#

install_gcc () {

  echo "Running ${FUNCNAME[0]} ..."

  # TODO: upgrade to newer version of GCC perhaps

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  # TODO: Rebuild all using x86_64
  spack install $SPACKOPTS gcc@$GCC_VER

  spack compiler add `spack location -i gcc@$GCC_VER`/bin

  # Use a gcc 8.5.0 "bootstrapped" gcc 8.5.0
  # This only works if gcc 8.5.0 is already installed
  # spack install $SPACKOPTS gcc@$GCC_VER %gcc@$GCC_VER
  # spack compiler add `spack location -i gcc@$GCC_VER`/bin
 
  cd $home
}

#-----------------------------------------------------------------------------#

install_intel_oneapi () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh 
  spack install $SPACKOPTS intel-oneapi-compilers@${INTEL_VER}

  spack compiler add `spack location -i intel-oneapi-compilers`/compiler/latest/linux/bin/intel64
  spack compiler add `spack location -i intel-oneapi-compilers`/compiler/latest/linux/bin

  spack install $SPACKOPTS intel-oneapi-mpi@${INTEL_VER} %intel@${INTEL_VER}
  spack install $SPACKOPTS intel-oneapi-mkl@${INTEL_VER} %intel@${INTEL_VER}

  cd $home
}

#-----------------------------------------------------------------------------#

install_netcdf () {

  echo "Running ${FUNCNAME[0]} ..."

  COMPILER=intel@${INTEL_VER}

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  # use diffutils@3.7 - intel compiler fails with 3.8
  # use m4@1.4.17     - intel compiler fails with newer versions

  # netcdf not built by intel ??
  # spack install $SPACKOPTS netcdf-fortran ^netcdf-c@4.8.0 ^hdf5@1.10.7+cxx+fortran+hl+szip+threadsafe \
  #    ^intel-oneapi-mpi@${INTEL_VER}%gcc@${GCC_VER} ^diffutils@3.7 ^m4@1.4.17 %${COMPILER}

  # Overriding some defaults for hdf5
  spack install $SPACKOPTS netcdf-fortran%${COMPILER} ^netcdf-c@4.8.0%${COMPILER} ^hdf5@1.10.7+cxx+fortran+hl+szip+threadsafe%${COMPILER} \
     ^intel-oneapi-mpi@${INTEL_VER}%gcc@${GCC_VER} ^diffutils@3.7 ^m4@1.4.17 %${COMPILER}

  cd $home
}

#-----------------------------------------------------------------------------#

install_hdf5-gcc8 () {

  # This installs the gcc built hdf5
  echo "Running ${FUNCNAME[0]} ..."

  COMPILER=gcc@${GCC_VER}

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  # use diffutils@3.7 - intel compiler fails with 3.8
  # use m4@1.4.17     - intel compiler fails with newer versions

  # spack install $SPACKOPTS cmake %gcc@$GCC_VER

  spack install $SPACKOPTS hdf5@1.10.7+cxx+fortran+hl+ipo~java+shared+tools \
     ^intel-oneapi-mpi@${INTEL_VER}%gcc@${GCC_VER} ^diffutils@3.7 ^m4@1.4.17 %${COMPILER}

  cd $home
}

#-----------------------------------------------------------------------------#

install_munge_s3 () {
  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  mkdir /tmp/munge
  cd /tmp/munge

  wget -nv https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/munge-0.5.14-rpms.tgz
  tar -xvzf munge-0.5.14-rpms.tgz
  sudo yum -y localinstall munge-0.5.14-2.el7.x86_64.rpm munge-devel-0.5.14-2.el7.x86_64.rpm \
     munge-libs-0.5.14-2.el7.x86_64.rpm

  sudo -u munge /usr/sbin/mungekey --verbose 

  sudo systemctl enable munge
  sudo systemctl start munge

  cd $home
}



#-----------------------------------------------------------------------------#

get_module_path () {

  # Need to include at least a partial hash if multiple packages with the 
  # same name are installed

  . /usr/share/Modules/init/bash

  
  if [ $# -ne 2 ]; then
    echo "Usage: get_module_path <module name> <end path>"
    return 1
  fi

  mod_name=$1
  end_path=$2

  module=`module avail $mod_name 2>&1 | grep $mod_name`

  if [ $? -eq 0 ]; then
    if [[ $end_path == 'bin' ]]; then
       path=`module show $module 2>&1 | grep 'PATH' | awk '{print $3}'`
       echo ${path}
    elif [[ $end_path == 'sbin' ]]; then
       path=`module show $module 2>&1 | grep CMAKE_PREFIX_PATH | awk '{print $3}'`
       echo ${path}sbin
    else 
      echo "ERROR: un-supported path $end_path"
      return 1
    fi
  else
    echo "ERROR: No module was found for $mod_name"
    return 2
  fi

  return 0
}

#-----------------------------------------------------------------------------#

add_module_sbin_path () {

  . /usr/share/Modules/init/bash

  if [ $# -ne 1 ]; then
    echo "Usage: ${FUNCNAME[0]} <module name>"
    return 1
  fi

  mod_name=$1

  module=`module avail $mod_name 2>&1 | grep $mod_name`

  if [ $? -eq 0 ]; then
    echo "$mod_name module found, adding sbin to PATH"
    ADDPATH=`module show $module 2>&1 | grep CMAKE_PREFIX_PATH | awk '{print $3}'`
    echo "export PATH=${ADDPATH}sbin:\$PATH" >> ~/.bashrc
    export PATH=${ADDPATH}sbin:$PATH
  else
    echo "ERROR: No module was found for $mod_name"
    return 2
  fi

  return 0
}

#-----------------------------------------------------------------------------#

install_slurm () {

  echo "Running ${FUNCNAME[0]} ..."

  # COMPILER=intel@${INTEL_VER}
  COMPILER=gcc@${GCC_VER}

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  # Munge is a prerequisite for slurm, custom options being used here 
  _install_munge
  result=$?
  if [ $result -ne 0 ]; then
    return $result
  fi

  spack install $SPACKOPTS --no-checksum slurm@${SLURM_VER}+hwloc+pmix sysconfdir=/etc/slurm ^tar@1.34%gcc@${GCC_VER}  \
     ^munge localstatedir=/var ^intel-oneapi-mpi@${INTEL_VER} %${COMPILER}

  add_module_sbin_path slurm
  result=$?

  if [ $result != 0 ]; then
    return $result
  fi

  sudo useradd --system --shell "/sbin/nologin" --home-dir "/etc/slurm" --comment "Slurm system user" slurm

  #(null): _log_init: Unable to open logfile `/var/log/slurm/slurmctld.log': Permission denied
  #slurmctld: error: Unable to open pidfile `/var/run/slurmctld.pid': Permission denied

  sudo mkdir -p /var/spool/slurmd

  sudo mkdir -p /var/spool/slurm
  sudo chgrp -R slurm /var/spool/slurm
  sudo chmod g+rw /var/spool/slurm

  sudo mkdir -p /var/log/slurm
  sudo chgrp -R slurm /var/log/slurm
  sudo chmod g+rw /var/log/slurm

  sudo mkdir  /etc/slurm
  sudo cp -pf slurm.conf /etc/slurm/slurm.conf
 
  cd $home
}

#-----------------------------------------------------------------------------#

_install_munge () {

  echo "Running ${FUNCNAME[0]} ..."

  # COMPILER=intel@${INTEL_VER}
  COMPILER=gcc@${GCC_VER}

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  sudo useradd --system --shell "/sbin/nologin" --home-dir "/etc/munge" --comment "Munge system user" munge

  sudo mkdir    /etc/munge
  sudo mkdir -p /var/log/munge
  sudo mkdir -p /var/lib/munge
  sudo mkdir -p /run/munge

  sudo chown -R munge:munge /etc/munge
  sudo chown -R munge:munge /var/log/munge
  sudo chown -R munge:munge /var/lib/munge
  sudo chown -R munge:munge /run/munge

  spack install $SPACKOPTS munge localstatedir=/var %${COMPILER}
  result=$?
  if [ $result -ne 0 ]; then
    return $result
  fi

  
  spack load munge
  result=$?
  if [ $result -ne 0 ]; then
    echo "ERROR: No package found for munge"
    return $result
  fi

  add_module_sbin_path munge
  result=$?
  if [ $result != 0 ]; then
    return $result
  fi

  sbindir=$(get_module_path munge sbin)

  sudo -u munge ${sbindir}/mungekey --create --keyfile=/etc/munge/munge.key  --verbose

  sed -e "s|@sbindir[@]|$sbindir|g" system/munge.service.in | sudo tee /usr/lib/systemd/system/munge.service 1>& /dev/null

  sudo systemctl enable munge
  sudo systemctl start munge
}

#-----------------------------------------------------------------------------#

configure_slurm () { 

  if [ $# -ne 1 ]; then
    echo "ERROR: ${FUNCNAME[0]} <compute | head>"
    return 1
  fi

  if [[ $1 == "compute" ]]; then
    nodetype="compute"
  elif [[ $1 == "head" ]]; then
    nodetype="head"
  else
    echo "ERROR: $1 is unknown. Usage: ${FUNCNAME[0]} <compute | head>"
    return 2
  fi

  echo "Running ${FUNCNAME[0]} $1 ..."

  spack load slurm
  result=$?
  if [ $result -ne 0 ]; then
    echo "ERROR: No package found for slurm"
    return $result
  fi

  add_module_sbin_path slurm
  result=$?
  if [ $result != 0 ]; then
    return $result
  fi

  sbindir=$(get_module_path slurm sbin)
  echo "sbindir: $sbindir"
 
  # Exclusive or 
  if [[ $nodetype == "head" ]]; then

    # slurmctld runs as slurm user

    # sed -e "s|@sbindir[@]|$sbindir|g" system/slurmctld.service.in | sudo tee /usr/lib/systemd/system/slurmctld.service 1>& /dev/null
    sed -e "s|@sbindir[@]|$sbindir|g" system/slurmctld.service.in | sudo tee /usr/lib/systemd/system/slurmctld.service 1>& /dev/null

    # First check if slurmd is installed
    resp=`which slurmd > /dev/null 2>&1; echo $?`
    if [ $resp -eq 0 ]; then
      [ `systemctl is-active  slurmd` == 'active'  ] && sudo systemctl stop    slurmd
      [ `systemctl is-enabled slurmd` == 'enabled' ] && sudo systemctl disable slurmd
    fi

    sudo systemctl enable slurmctld
    sudo systemctl start slurmctld

    # slurmctld: error: power_save program /opt/parallelcluster/scripts/slurm/slurm_suspend not executable
    # slurmctld: error: power_save module disabled, invalid SuspendProgram /opt/parallelcluster/scripts/slurm/slurm_suspend

  else   # compute node

    # slurmd runs as root
    sed -e "s|@sbindir[@]|$sbindir|g" system/slurmd.service.in | sudo tee /usr/lib/systemd/system/slurmd.service 1>& /dev/null

    # First check if slurmctld is installed
    resp=`which slurmctld > /dev/null 2>&1; echo $?`
    if [ $resp -eq 0 ]; then
      [ `systemctl is-active  slurmctld` == 'active'  ] && sudo systemctl stop    slurmctld
      [ `systemctl is-enabled slurmctld` == 'enabled' ] && sudo systemctl disable slurmctld
    fi
    sudo systemctl enable slurmd
    sudo systemctl start slurmd
  fi

}

#-----------------------------------------------------------------------------#


install_slurm-epel7 () {
#-----------------------------------------------------------------------------#
# NOTE: In the beginning of 2021, a version of Slurm was added to the EPEL repository. This version is not supported or maintained by SchedMD, and is not currently recommend for customer use. Unfortunately, this inclusion could cause Slurm to be updated to a newer version outside of a planned maintenance period. In order to prevent Slurm from being updated unintentionally, we recommend you modify the EPEL Repository configuration to exclude all Slurm packages from automatic updates.

# exclude=slurm*
#-----------------------------------------------------------------------------#
  echo "Running ${FUNCNAME[0]} ..."

  nodetype="head"
  if [ $# -gt 1 ]; then 
    if [[ $1 == "compute" ]]; then
      nodetype="compute"
    fi
  fi

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  spack load gcc@8.5.0

  # install on all nodes
  sudo yum -y install slurm slurm-libs
  sudo yum -y install slurm-perlapi

  #sudo yum -y install slurm-openlava
  #sudo yum -y install slurm-slurmdbd
  #sudo yum -y install slurm-pam_slurm
  #sudo yum -y install slurm-pmi
  #sudo yum -y install slurm-slurmrestd

  sudo useradd --system --shell "/sbin/nologin" --home-dir "/etc/slurm" --comment "Slurm system user" slurm

  sudo mkdir -p /var/spool/slurm
  sudo mkdir -p /var/run/slurm

  sudo chown -R slurm /var/spool/slurm
  sudo chown -R slurm /var/run/slurm

  sudo mkdir    /etc/slurm
  sudo cp -pf slurm.conf /etc/slurm/slurm.conf

  # Head node or Compute node?
  # Although it is possible to use the head node as a compute node also,
  # we are making sure we only have one or the other setup here 
  # to help ensure the image taken is only for one or the other
  # The snapshot can be taken after running either setup

  # Exclusive or 
  if [[ $nodetype == "head" ]]; then 

    # needed on head node only
    sudo yum -y install slurm-slurmctld

    # First check if slurmd is installed
    resp=`which slurmd > /dev/null 2>&1; echo $?`
    if [ $resp -eq 0 ]; then
      [ `systemctl is-active  slurmd` == 'active'  ] && sudo systemctl stop    slurmd
      [ `systemctl is-enabled slurmd` == 'enabled' ] && sudo systemctl disable slurmd
    fi

    sudo systemctl enable slurmctld
    sudo systemctl start slurmctld
  else

    # needed on compute nodes
    sudo yum -y install slurm-slurmd

    # First check if slurmctld is installed
    resp=`which slurmctld > /dev/null 2>&1; echo $?`
    if [ $resp -eq 0 ]; then
      [ `systemctl is-active  slurmctld` == 'active'  ] && sudo systemctl stop    slurmctld
      [ `systemctl is-enabled slurmctld` == 'enabled' ] && sudo systemctl disable slurmctld
    fi

    sudo systemctl enable slurmd
    sudo systemctl start slurmd
  fi

}

#-----------------------------------------------------------------------------#

install_slurm-s3() {
  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  mkdir /tmp/slurminstall
  cd /tmp/slurminstall

  wget -nv https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/slurm-20.11.5-rpms.tgz
  tar -xzvf slurm-20.11.5-rpms.tgz
  sudo yum -y localinstall slurm-20.11.5-1.el7.x86_64.rpm
}

#-----------------------------------------------------------------------------#

install_esmf () {

  echo "Running ${FUNCNAME[0]} ..."

  COMPILER=intel@${INTEL_VER}

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  # ^netcdf-c@4.8.0
  # ^hdf5@1.10.7+cxx+fortran+hl+szip+threadsafe

  spack install $SPACKOPTS esmf%${COMPILER} ^intel-oneapi-mpi@${INTEL_VER} ^diffutils@3.7 ^m4@1.4.17 \
     ^hdf5@1.10.7+cxx+fortran+hl+szip+threadsafe ^netcdf-c@4.8.0 %${COMPILER}


  # spack install $SPACKOPTS esmf%${COMPILER} ^intel-oneapi-mpi@${INTEL_VER}%gcc@${GCC_VER} ^diffutils@3.7 ^m4@1.4.17 \
  #    ^hdf5/qfvg7gc ^netcdf-c/yynmjgt

  cd $home
}

#-----------------------------------------------------------------------------#

install_base_rpms () {

  # TODO: refactor into one "install_nco_libs" function
  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  # gcc/6.5.0  hdf5/1.10.5  netcdf/4.5  produtil/1.0.18 esmf/8.0.0
  libstar=base_rpms.gcc.6.5.0.el7.20200716.tgz

  wrkdir=~/baserpms
  [ -e "$wrkdir" ] && rm -Rf "$wrkdir"
  mkdir -p "$wrkdir"
  cd "$wrkdir"

  wget -nv https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/$libstar
  tar -xf $libstar
  rm $libstar
 
  #rpmlist='
  #  hdf5-1.10.5-4.el7.x86_64.rpm
  #  netcdf-4.5-3.el7.x86_64.rpm
  #  produtil-1.0.18-2.el7.x86_64.rpm
  #  esmf-8.0.0-1.el7.x86_64.rpm
  #'

  rpmlist='
    produtil-1.0.18-2.el7.x86_64.rpm
  '

  for file in $rpmlist
  do
    sudo yum -y install $file
  done

  rm -Rf "$wrkdir"

  cd $home
}

#-----------------------------------------------------------------------------#

install_extra_rpms () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  # tarball contents
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

  wrkdir=/tmp/extrarpms
  [ -e "$wrkdir" ] && rm -Rf "$wrkdir"
  mkdir -p "$wrkdir"
  cd "$wrkdir"

  wget -nv https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/$libstar
  tar -xf $libstar
  rm $libstar

  for file in $rpmlist
  do
    sudo yum -y localinstall $file
  done

  # Force install newer libpng leaving the existing one intact
  # this one will be used for our model builds via the module
  #sudo rpm -v --install --force libpng-1.5.30-2.el7.x86_64.rpm  
  # refuses to upgrade #  sudo yum -y localinstall  libpng-1.5.30-2.el7.x86_64.rpm  
  # sudo yum -y downgrade  libpng-1.5.30-2.el7.x86_64.rpm  # WORKS - use spack instead

  # rm -Rf "$wrkdir"

  sudo yum -y install jasper-devel

  cd $home
}

#-----------------------------------------------------------------------------#

install_python_modules_user () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  sudo python3 -m pip install --upgrade pip
  python3 -m pip install --user --upgrade wheel
  python3 -m pip install --user --upgrade dask
  python3 -m pip install --user --upgrade distributed
  python3 -m pip install --user --upgrade setuptools_rust  # needed for paramiko
  python3 -m pip install --user --upgrade paramiko   # needed for dask-ssh
  python3 -m pip install --user --upgrade prefect

  # SPACK has problems with botocore newer than below
  python3 -m pip install --user --upgrade botocore==1.23.46
  # This is the most recent boto3 that is compatible with botocore above
  python3 -m pip install --user --upgrade boto3==1.20.46

  cd $home 
}

#-----------------------------------------------------------------------------#

install_plotting_modules () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  # Build and install the plotting module and its dependencies
  # must install from ~/Cloud-Sandbox/cloudflow
  cd ../..
  pwd
  python3 ./setup.py sdist
  python3 -m pip install --user dist/plotting-*.tar.gz

  cd $home
}

#-----------------------------------------------------------------------------#

install_python_modules_osx () {

  echo "Running ${FUNCNAME[0]} ..."

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

#-----------------------------------------------------------------------------#

install_ffmpeg () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  version=20200127
  tarfile=ffmpeg-git-i686-static.tar.xz

  wrkdir=~/ffmpeg
  [ -e "$wrkdir" ] && rm -Rf "$wrkdir"
  mkdir -p "$wrkdir"
  cd "$wrkdir"

  wget -nv https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/$tarfile
  tar -xf $tarfile
  rm $tarfile
 
  sudo mkdir -p /usrx/ffmpeg/$version
  sudo cp -Rp ffmpeg-git-${version}-i686-static/* /usrx/ffmpeg/$version

  sudo ln -sf /usrx/ffmpeg/${version}/ffmpeg /usr/local/bin

  rm -Rf "$wrkdir"

  cd $home
}

#-----------------------------------------------------------------------------#

install_ffmpeg_osx () {

  echo "Running ${FUNCNAME[0]} ..."

  which brew > /dev/null
  if [ $? -ne 0 ] ; then
    echo "Homebrew is missing ... install Homebrew then retry ... exiting"
    exit 1
  fi

  brew install ffmpeg
}

#-----------------------------------------------------------------------------#

setup_ssh_mpi () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  # MPI needs key to ssh into cluster nodes
  sudo -u centos ssh-keygen -t rsa -N ""  -C "mpi-ssh-key" -f /home/centos/.ssh/id_rsa
  sudo -u centos cat /home/centos/.ssh/id_rsa.pub >> /home/centos/.ssh/authorized_keys

  cat >> /etc/ssh/ssh_config <<EOL
Host ip-10-0-* 
   CheckHostIP no 
   StrictHostKeyChecking no 

Host 10.0.* 
   CheckHostIP no 
   StrictHostKeyChecking no
EOL

  cd $home
}

#-----------------------------------------------------------------------------#

create_ami_reboot () {

  # Create the AMI from this instance
  instance_id=`curl http://169.254.169.254/latest/meta-data/instance-id`

  # echo "Current instance is: $instance_id"

  echo "Creating an AMI of this instance ... will reboot automatically" >> /tmp/setup.log
  /usr/local/bin/aws --region ${aws_region} ec2 create-image --instance-id $instance_id --name "${ami_name}" \
    --tag-specification "ResourceType=image,Tags=[{Key=\"Name\",Value=\"${ami_name}\"},{Key=\"Project\",Value=\"${project}\"}]" \
    > /tmp/ami.log 2>&1

  # TODO: Check for errors returned from any step above

  imageID=`grep ImageId /tmp/ami.log`
  echo "imageID to use for compute nodes is: $imageID"
}

#-----------------------------------------------------------------------------#

create_snapshot () {

  # inputs: 
  #   message: string used for tagging
  #
  # outputs: the snapshotID to be used in other functions

  home=$PWD

  message=""
  if [ $# -eq 2 ]; then
    message=$1
  fi

  echo "create_snapshot: message is: $message"

  # AWS
  aws_region=`curl http://169.254.169.254/latest/meta-data/placement/region`
  instance_id=`curl http://169.254.169.254/latest/meta-data/instance-id`

  # TODO: remove hardcoded values
  name_tag="$message snapshot of $instance_id"
  echo "create_snapshot: name_tag is: $name_tag"

  # TODO: migrate project_tag in from Terraform
  project="IOOS-Cloud-Sandbox"

  response=`/usr/local/bin/aws --region ${aws_region} ec2 create-snapshots \
    --instance-specification "InstanceId=$instance_id,ExcludeBootVolume=false" \
    --copy-tags-from-source volume \
    --tag-specifications "ResourceType=snapshot,Tags=[{Key=\"Name\",Value=\"${name_tag}\"},{Key=\"Project\",Value=\"${project}\"}]"`

  snapshotId=`echo $response | jq '.Snapshots[].SnapshotId'`

  echo $snapshotId | awk -F\" '{print $2}'

  cd $home
}

#####################################################################

# Personal stuff here
setup_aliases () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  echo alias lsl ls -al >> ~/.tcshrc
  echo alias lst ls -altr >> ~/.tcshrc
  echo alias h history >> ~/.tcshrc

  echo alias cds cd /save/$user >> ~/.tcshrc
  echo alias cdns cd /noscrub/$user >> ~/.tcshrc
  echo alias cdpt cd /ptmp/$user >> ~/.tcshrc

  git config --global user.name "Patrick Tripp"
  git config --global user.email "44276748+patrick-tripp@users.noreply.github.com"
  git commit --amend --reset-author

  #git config user.name "Patrick Tripp"
  #git config user.email "44276748+patrick-tripp@users.noreply.github.com"

  cd $home
}

