#  1 = Don't build any packages. Only install packages from binary mirrors
#  0 = Will build if not found in mirror/cache
# -1 = Don't check pre-built binary cache

if [ $SPACK_CACHEONLY -eq 1 ]; then
  SPACKOPTS="$SPACKOPTS --cache-only"
elif [ $SPACK_CACHEONLY -eq -1 ]; then
  SPACKOPTS="$SPACKOPTS --no-cache"
fi

# This script will setup the required system components, libraries
# and tools needed for ROMS forecast models on CentOS 7

#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

# This has been tested on RHEL8 

setup_environment () {

  # TODO: add etc/profile.d customizations - see ./system directory
  # TODO: add .vimrc to ~ to turn off auto-indent - see ./system directory

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  # By default, centos 7 does not install the docs (man pages) for packages, remove that setting here
  sudo sed -i 's/tsflags=nodocs/# &/' /etc/yum.conf

  # Get rid of subscription manager messages
  sudo subscription-manager config --rhsm.manage_repos=0
  sudo sed -i 's/enabled[ ]*=[ ]*1/enabled=0/g' /etc/yum/pluginconf.d/subscription-manager.conf

  sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

  # yum update might update the kernel. 
  # This might cause some of the other installs to fail, e.g. efa driver 
  #sudo yum -y update

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
  sudo yum -y install subversion
  sudo yum -y install bc
  sudo yum -y install htop

  sudo yum -y install python3.11-devel
  sudo alternatives --set python3 /usr/bin/python3.11
  sudo yum -y install python3.11-pip
  sudo yum -y install jq

  # Additional packages for spack-stack
  #sudo yum -y install git-lfs
  #sudo yum -y install bash-completion
  #sudo yum -y install xorg-x11-xauth
  #sudo yum -y install xterm
  #sudo yum -y install texlive
  #sudo yum -y install mysql-server

  cliver="2.10.0"
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${cliver}.zip" -o "awscliv2.zip"
  /usr/bin/unzip -q awscliv2.zip
  sudo ./aws/install
  rm awscliv2.zip
  sudo rm -Rf "./aws"

  sudo yum -y install environment-modules

  # Only do this once
  grep "/usr/share/Modules/init/bash" ~/.bashrc >& /dev/null
  if [ $? -eq 1 ] ; then
    echo . /usr/share/Modules/init/bash >> ~/.bashrc
    echo source /usr/share/Modules/init/tcsh >> ~/.tcshrc 
    . /usr/share/Modules/init/bash
  fi

  # Only do this once
  if [ ! -d /save/environments/modulefiles ] ; then
    sudo mkdir -p /save/environments/modulefiles
    echo "/save/environments/modulefiles" | sudo tee -a ${MODULESHOME}/init/.modulespath
    echo "/usrx/modulefiles" | sudo tee -a ${MODULESHOME}/init/.modulespath
    echo ". /usr/share/Modules/init/bash" | sudo tee -a /etc/profile.d/custom.sh
    echo "source /usr/share/Modules/init/csh" | sudo tee -a /etc/profile.d/custom.csh
    echo "module use -a /usrx/modulefiles" >> ~/.bashrc
    . ~/.bashrc
  fi

  # Add unlimited stack size 
  echo "ulimit -s unlimited" | sudo tee -a /etc/profile.d/custom.sh

  # sudo yum clean {option}
  cd $home

}

#-----------------------------------------------------------------------------#

setup_paths () {

  echo "Running ${FUNCNAME[0]} ..."

  set -x
  home=$PWD

  if [ ! -d /mnt/efs/fs1 ]; then
    echo "ERROR: EFS disk is not mounted"
    exit 1
  fi

  cd /mnt/efs/fs1

  if [ ! -d ptmp ] ; then
    sudo mkdir ptmp
    sudo chgrp wheel ptmp
    sudo chmod 777 ptmp
    sudo ln -s /mnt/efs/fs1/ptmp /ptmp
  fi

  if [ ! -d com ] ; then
    sudo mkdir com
    sudo chgrp wheel com
    sudo chmod 777 com
    sudo ln -s /mnt/efs/fs1/com  /com
  fi

# Not sure why it keeps creating an extra sym link
#  if [ ! -d save ] ; then
#    sudo mkdir save
#    sudo chgrp wheel save
#    sudo chmod 777 save
#    sudo ln -s /mnt/efs/fs1/save /save
#  fi

  # mkdir /save/$USER
  mkdir /com/$USER
  mkdir /ptmp/$USER

  set +x
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
  echo "!!!!!!!!!               INSTALLING EFA DRIVER                !!!!!!!!!"
  echo "!!!!!!!!!     DO NOT KILL OR PRESS CTL-C UNTIL COMPLETED     !!!!!!!!!"

# This must be installed before the rest

# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/efa-start.html

  home=$PWD

  version=$EFA_INSTALLER_VER

  # version=latest
  # version=1.14.1  # Last one with CentOS 8 support
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

  # System default gcc version is needed to build the kernel driver
  curl -s -O https://s3-us-west-2.amazonaws.com/aws-efa-installer/$tarfile
  tar -xf $tarfile
  rm $tarfile

  cd aws-efa-installer

  # hpc7a did not work with intel MPI and the AWS libfabric
  EFA_MINAMAL="YES"

  if [[ $EFA_MINIMAL == "NO" ]]; then
    # Install with AWS libfabric and OpenMPI, need to fix PATH prefix the forces OpenMPI mpirun and mpifort.
    sudo ./efa_installer.sh -y

    # If it installed openmpi, undo the profile.d change the installer made
    sudo cp $home/system/profile.d.zippy_efa.sh /etc/profile.d/zippy_efa.sh

  else
    # Install without AWS libfabric and OpenMPI, we will use Intel libfabric and MPI
    sudo ./efa_installer.sh -y --minimal
  fi

  # Put old kernels back in original location in case new kernel fails to boot, can revert if needed
  if [ $(ls /usr/lib/oldkernel/ | wc -l) -ne 0 ]; then
    sudo mv /usr/lib/oldkernel/*  /usr/lib/modules
    sudo rmdir /usr/lib/oldkernel
  fi

  cd $home
  echo "!!!!!!!!!    EFA INSTALLER COMPLETED    !!!!!!!!!"
}

#-----------------------------------------------------------------------------#
# Not currently used
install_gcc_toolset_yum() {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  sudo yum -y install gcc-toolset-11-gcc-c++
  sudo yum -y install gcc-toolset-11-gcc-gfortran
  sudo yum -y install gcc-toolset-11-gdb
 
  # scl enable gcc-toolset-11 bash - Not inside a script
  # source scl_source enable gcc-toolset-11
  # source /opt/rh/gcc-toolset-11/enable 
  cd $home
}

#-----------------------------------------------------------------------------#
# Not currently used - needs work
install_spack-stack() {

  echo "Running ${FUNCNAME[0]} ..."
  home=$PWD

  SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'
  SPACK_KEY_URL='https://ioos-cloud-sandbox.s3.amazonaws.com/public/spack/mirror/spack.mirror.gpgkey.pub'
  SPACK_KEY="$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.pub"

  cd /save/environments
  git clone --recurse-submodules -b ioos-aws https://github.com/asascience/spack-stack.git
  cd spack-stack
  source setup.sh

  # To be continued ....

}

#-----------------------------------------------------------------------------#

install_spack() {

  echo "Running ${FUNCNAME[0]} ..."
  home=$PWD

  source /opt/rh/gcc-toolset-11/enable

  SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'
  SPACK_KEY_URL='https://ioos-cloud-sandbox.s3.amazonaws.com/public/spack/mirror/spack.mirror.gpgkey.pub'
  SPACK_KEY="$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.pub"

  echo "Installing SPACK in $SPACK_DIR ..."

  if [ ! -d /save ] ; then
    echo "/save does not exst. Setup the paths first."
    return
  fi

  sudo mkdir -p $SPACK_DIR
  sudo chown ec2-user:ec2-user $SPACK_DIR
  git clone -q https://github.com/spack/spack.git $SPACK_DIR
  cd $SPACK_DIR
  git checkout -q $SPACK_VER

  # Don't add this if it is already there
  grep "\. $SPACK_DIR/share/spack/setup-env.sh" ~/.bashrc >& /dev/null
  if [ $? -eq 1 ] ; then 
      echo ". $SPACK_DIR/share/spack/setup-env.sh" >> ~/.bashrc
      echo "source $SPACK_DIR/share/spack/setup-env.csh" >> ~/.tcshrc 
  fi

  # Location for overriding default configurations
  sudo mkdir /etc/spack
  sudo chown ec2-user:ec2-user /etc/spack
 
  . $SPACK_DIR/share/spack/setup-env.sh

  # TODO: Rebuild everything using this, and push to mirror
  spack config add "config:install_tree:padded_length:73"
  spack config add "modules:default:enable:[tcl]"

  # Using an s3-mirror for previously built packages
  echo "Using SPACK s3-mirror $SPACK_MIRROR"
  spack mirror add s3-mirror $SPACK_MIRROR
  spack buildcache keys --install --trust --force

  spack buildcache update-index $SPACK_MIRROR
  #     update-index (same as rebuild-index)
  #               update a buildcache index

  spack compiler find --scope system

  ###############################################
  # Use system installed packages when available
  # had some gettext build issues, using the system one resolved it
  ###############################################
  # scope 
  # site -- changes saved in SPACK_DIR
  # system -- changes globally in /etc/spack
  # user -- changes in ~/.spack

  spack external find --scope site
  # spack external find --not-buildable --scope site
  # --not-buildable       packages with detected externals won't be built with Spack

  # Note: to recreate modulefiles
  # spack module tcl refresh -y

  # This is spack's mirror of some libraries
  #spack mirror add v0.22.5 https://binaries.spack.io/v0.22.5
  #spack buildcache keys --install --trust

  cd $home
}

#-----------------------------------------------------------------------------#
# Uninstalls everything
remove_spack() {
  set +x

  echo "In remove_spack() ..."
  echo "WARNING: This will remove everything in $SPACK_DIR and /etc/spack"
  echo "Proceed with caution, this action might affect other users"
  read -r -p "Do you want to proceed? (y/N): " response
  case "$response" in
        [Yy]* ) echo "Proceeding ..." ;;
        * ) echo "Operation cancelled. Exiting."; exit;;
  esac

  set -x
  if [ ! -d /etc/spack ] ; then
    echo "WARNING: /etc/spack not found, nothing to clean "
  else
    cd /etc/spack || exit 1
    rm -f compilers.yaml
    rm -f packages.yaml
    cd ..
    sudo rmdir spack
    cd $home
  fi

  if [ ! -d ~/.spack ] ; then
    echo "WARNING: ~/.spack not found, nothing to clean"
  else
    cd ~/.spack || exit 1
    rm -Rf bootstrap/
    rm -Rf cache/
    rm -Rf linux/
    rm -f *
    cd ..
    rmdir .spack
    cd $home
  fi

  if [ ! $SPACK_DIR ] || [ ! -d $SPACK_DIR ] ; then
    echo "WARNING: $SPACK_DIR not found, nothing to clean"
  else
    cd $SPACK_DIR || exit 1
    rm -Rf *
    rm -Rf .[a-Z]*
    cd ..
    sudo rmdir $SPACK_DIR
    cd $home
  fi

  set +x
}

#-----------------------------------------------------------------------------#
# Not currently used, using gcc toolset
install_gcc_spack () {

  echo "Running ${FUNCNAME[0]} ..."

  # TODO: upgrade to newer version of GCC perhaps

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  # TODO: Rebuild all using x86_64
  spack install $SPACKOPTS --no-checksum gcc@$GCC_VER ^ncurses@6.4 $SPACKTARGET

  spack compiler add `spack location -i gcc@$GCC_VER`/bin

  # Use a gcc 8.5.0 "bootstrapped" gcc 8.5.0
  # This only works if gcc 8.5.0 is already installed
  # spack install $SPACKOPTS gcc@$GCC_VER %gcc@$GCC_VER
  # spack compiler add `spack location -i gcc@$GCC_VER`/bin
 
  cd $home
}

#-----------------------------------------------------------------------------#
# Not currently used - needs work
install_intel_oneapi-spack-stack () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  cd $SPACK_DIR
  source setup.sh
  SPACK_ENV=ioos-aws-rhel

  cd $SPACK_ENV 
  spack env activate -p .
  spack install $SPACKOPTS intel-oneapi-compilers@${INTEL_VER}
  spack compiler add `spack location -i intel-oneapi-compilers`/compiler/${INTEL_VER}/linux/bin/intel64
  spack compiler add `spack location -i intel-oneapi-compilers`/compiler/${INTEL_VER}/linux/bin

  spack install $SPACKOPTS intel-oneapi-mpi@${INTEL_VER} %intel@${INTEL_VER}
  spack install $SPACKOPTS intel-oneapi-mkl@${INTEL_VER} %intel@${INTEL_VER}

  cd $home
}

#-----------------------------------------------------------------------------#
# Not currently used
install_intel_oneapi_yum () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

tee > /tmp/oneAPI.repo << EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF

sudo mv /tmp/oneAPI.repo /etc/yum.repos.d

sudo rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB

# sudo yum -y install intel-oneapi-compiler-dpcpp-cpp-2023.1.0.x86_64
# sudo yum -y install intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-2023.1.0.x86_64
# sudo yum -y install intel-oneapi-compiler-fortran-2023.1.0.x86_64
# sudo yum -y install --installroot /apps intel-hpckit-2023.1.0.x86_64

sudo yum -y install intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-2023.1.0.x86_64
sudo yum -y install intel-oneapi-compiler-fortran-2023.1.0.x86_64

mkdir /save/environments/modulefiles

cd /opt/intel/oneapi/
./modulefiles-setup.sh --ignore-latest --output-dir=/mnt/efs/fs1/save/environments/modulefiles
module use -a /save/environments/modulefiles

cd $home

}

#-----------------------------------------------------------------------------#

install_intel_oneapi_spack () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh 

  source /opt/rh/gcc-toolset-11/enable

  #GCC_COMPILER=`spack compilers | grep "gcc@11\."`
  GCC_COMPILER=gcc@$GCC_VER

  # spack install $SPACKOPTS intel-oneapi-compilers@${ONEAPI_VER} $SPACKTARGET

  # gmake@4.4.1 build fails when built here
  # gmake.4.2.1 build does not work either
  # gmake.4.2.1 as a pre-req works when specifying it as an external in /etc/spack/packages.yaml
  #spack install $SPACKOPTS intel-oneapi-compilers@${ONEAPI_VER} ^gmake@4.2.1 $SPACKTARGET
  spack install $SPACKOPTS intel-oneapi-compilers@${ONEAPI_VER} $SPACKTARGET

  spack compiler add --scope site `spack location -i intel-oneapi-compilers \%${GCC_COMPILER}`/compiler/latest/linux/bin/intel64
  spack compiler add --scope site `spack location -i intel-oneapi-compilers \%${GCC_COMPILER}`/compiler/latest/linux/bin

  cd $home
}



install_intel-oneapi-mkl_spack () {
  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  source /opt/rh/gcc-toolset-11/enable

  set -x
  spack load intel-oneapi-compilers@$ONEAPI_VER

  # Build with Intel OneApi compilers
  # use m4@1.4.17     - intel compiler fails with newer versions

  # netcdf-c@4.8.0 ^hdf5@1.10.7+cxx+fortran+hl+szip+threadsafe \
  #    ^intel-oneapi-mpi@${INTEL_VER}%gcc@${GCC_VER} ^diffutils@3.7 ^m4@1.4.17 %${COMPILER}

  #spack install $SPACKOPTS intel-oneapi-mkl@${ONEAPI_VER} %oneapi@${ONEAPI_VER} $SPACKTARGET
  #/tmp/ec2-user/spack-stage/spack-stage-m4-1.4.19-36watno3kqa6bsuopisfn3jq72cp247y/spack-build-out.txt
  # It is not finding libimf.so - intel math library - annoying
  # Need to imanually add rpath to compilers.yaml - but this worked before wth!
  # trying witn m4@1.4.17 since it is a previous make error before libimf.so error - nope, still cant find it
  # spack install $SPACKOPTS intel-oneapi-mkl@${ONEAPI_VER} ^m4@1.4.17 %oneapi@${ONEAPI_VER} $SPACKTARGET
  # ran spack external find m4, found v 1.4.18 on system, trying that
  spack install $SPACKOPTS intel-oneapi-mkl@${ONEAPI_VER} ^m4@1.4.18 %oneapi@${ONEAPI_VER} $SPACKTARGET

  set +x

  cd $home
}


#-----------------------------------------------------------------------------#
# Not currently used, netcdf is installed with esmf
install_netcdf () {

  echo "Running ${FUNCNAME[0]} ..."
  echo "Out of date ... returning"
  return

  COMPILER=${COMPILER:-intel@${INTEL_VER}}

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  # use diffutils@3.7 - intel compiler fails with 3.8
  # use m4@1.4.17     - intel compiler fails with newer versions

  # netcdf not built by intel ??
  # spack install $SPACKOPTS netcdf-fortran ^netcdf-c@4.8.0 ^hdf5@1.10.7+cxx+fortran+hl+szip+threadsafe \
  #    ^intel-oneapi-mpi@${INTEL_VER}%gcc@${GCC_VER} ^diffutils@3.7 ^m4@1.4.17 %${COMPILER}

  # Overriding some defaults for hdf5
  # spack install $SPACKOPTS netcdf-fortran%${COMPILER} ^netcdf-c@4.8.0%${COMPILER} ^hdf5@1.10.7+cxx+fortran+hl+szip+threadsafe%${COMPILER} \
  #   ^intel-oneapi-mpi@${INTEL_VER}%gcc@${GCC_VER} ^diffutils@3.7 ^m4@1.4.17 %${COMPILER}

  # HDF5 also needs szip lib
  spack install $SPACKOPTS libszip%${COMPILER}

  cd $home
}

#-----------------------------------------------------------------------------#
# Not currently used
install_hdf5-gcc8 () {

  # This installs the gcc built hdf5
  echo "Running ${FUNCNAME[0]} ..."
  echo "Out of date ... returning"
  return

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
# Not currently used
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
# Not currently used - and currently not planning on using slurm
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

  MUNGEDEP=`spack find --format "{name}/{hash}" munge`

  echo "MUNGEDEP: $MUNGEDEP"

  spack load intel-oneapi-mpi@${INTEL_VER}%${COMPILER}

 #spack install $SPACKOPTS --no-checksum slurm@${SLURM_VER}+hwloc+pmix sysconfdir=/etc/slurm ^tar@1.34%gcc@${GCC_VER}  \
  # hwloc build is failing, netloc_mpi_find_hosts.c:116: undefined reference to `MPI_Send' etc.
     #^"$MUNGEDEP" localstatedir='/var' ^intel-oneapi-mpi@${INTEL_VER} %${COMPILER}

  # Build issues with hdf5, hwloc, and pmix .. will resolve later if needed
  spack install $SPACKOPTS --no-checksum slurm@${SLURM_VER}~hdf5~hwloc~pmix sysconfdir=/etc/slurm ^tar@1.34%gcc@${GCC_VER}  \
       ^"$MUNGEDEP" ^intel-oneapi-mpi@${INTEL_VER} %${COMPILER}

  add_module_sbin_path slurm
  result=$?

  if [ $result != 0 ]; then
    return $result
  fi

  echo "Adding slurm system user ..."
  sudo useradd --system --shell "/sbin/nologin" --home-dir "/etc/slurm" --comment "Slurm system user" slurm

  #(null): _log_init: Unable to open logfile `/var/log/slurm/slurmctld.log': Permission denied
  #slurmctld: error: Unable to open pidfile `/var/run/slurmctld.pid': Permission denied

  sudo mkdir -p /var/spool/slurmd
  sudo mkdir -p /var/spool/slurm

  #sudo chgrp -R slurm /var/spool/slurm
  #sudo chmod g+rw /var/spool/slurm

  #sudo mkdir -p /var/log/slurm
  #sudo chgrp -R slurm /var/log/slurm
  #sudo chmod g+rw /var/log/slurm

  echo "Copying slurm.conf to /etc/slurm ..."
  sudo mkdir  /etc/slurm
  sudo cp -pf system/slurm.conf /etc/slurm/slurm.conf
 
  cd $home
}

#-----------------------------------------------------------------------------#
# Not currently used - slurm dependency
_install_munge () {

  # https://github.com/dun/munge/wiki/Installation-Guide
  echo "Running ${FUNCNAME[0]} ..."

  # COMPILER=intel@${INTEL_VER}
  COMPILER=gcc@${GCC_VER}

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  sudo useradd --system --shell "/sbin/nologin" --home-dir "/etc/munge" --comment "Munge system user" munge

  sudo mkdir -p /etc/munge
  sudo mkdir -p /var/log/munge
  sudo mkdir -p /var/lib/munge
  sudo mkdir -p /run/munge

  sudo chown munge:munge /etc/munge
  sudo chown munge:munge /var/log/munge
  sudo chown munge:munge /var/lib/munge
  sudo chown munge:munge /run/munge

  #spack install $SPACKOPTS munge localstatedir=/var %${COMPILER}
  spack install $SPACKOPTS munge runstatedir=/run localstatedir=/var %${COMPILER}
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
# Not currently used - and currently not planning on using slurm
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

  . $SPACK_DIR/share/spack/setup-env.sh

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

  # Load the modified PATH 
  . ~/.bashrc

  sbindir=$(get_module_path slurm sbin)
 
  # Exclusive or 
  if [[ $nodetype == "head" ]]; then

    # slurmctld runs as slurm user

    sed -e "s|@sbindir[@]|$sbindir|g" system/slurmctld.service.in | sudo tee /usr/lib/systemd/system/slurmctld.service 1>& /dev/null

    # First check if slurmd is installed, slurmd only runs on compute nodes
    resp=`which slurmd > /dev/null 2>&1; echo $?`
    if [ $resp -eq 0 ]; then
      [ `systemctl is-active  slurmd` == 'active'  ] && sudo systemctl stop slurmd
      slurmd_enabled=`systemctl is-enabled slurmd 2> /dev/null`
      [ "$slurmd_enabled" == 'enabled' ] && sudo systemctl disable slurmd
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
      slurmctld_enabled=`systemctl is-enabled slurmctld 2> /dev/null`
      [ "$slurmctld_enabled" == 'enabled' ] && sudo systemctl disable slurmctld
    fi
    sudo systemctl enable slurmd
    sudo systemctl start slurmd
  fi

}

#-----------------------------------------------------------------------------#


# Not currently used - and currently not planning on using slurm
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
# Not currently used - and currently not planning on using slurm
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

install_esmf_spack () {

  # Install esmf along with esmf dependencies such as netcdf and hdf5

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  #spack load intel-oneapi-compilers@${ONEAPI_VER}
  #spack load intel-oneapi-mkl@${ONEAPI_VER}

  COMPILER=intel@${INTEL_COMPILER_VER}
  #COMPILER=oneapi@${ONEAPI_VER}   # v8.5 and v8.6 build errors with oneapi compilers, use intel classic, maybe try a newer version of oneapi compilers

  # oneapi mpi spack build option
      # external-libfabric [false]        false, true
      # Enable external libfabric dependency

  # diffutils 3.10 build fails
  #    using ^diffutils@3.7
  #spack install $SPACKOPTS esmf@${ESMF_VER}%${COMPILER} ^intel-oneapi-mpi@${INTEL_MPI_VER}%${COMPILER} ^diffutils@3.7 %${COMPILER} $SPACKTARGET

  # Using built in externals diffutils
  #spack install $SPACKOPTS esmf@${ESMF_VER}%${COMPILER} ^intel-oneapi-mpi@${INTEL_MPI_VER}%${COMPILER} %${COMPILER} $SPACKTARGET
  #spack install -j 4 $SPACKOPTS esmf@${ESMF_VER}%${COMPILER} ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET

  # esmf 8.5.0 getting segmentation error during build, trying 8.6.0
  # 8.6.0 had same error - rebooting setting -j 4 sometimes parallel compilation causes weird errors
#         #17 0x000014b6651587e5 __libc_start_main + 229
#         #18 0x0000000001cf1729
#
#/tmp/ifx1897599690HSlFpB/ifxvctKti.i90: error #5633: **Internal compiler error: segmentation violation signal raised** Please report this error along with the circumstances in which it occurred in a Software Problem Report.  Note: File and line given may not be explicit cause of this error.
#
  #spack install $SPACKOPTS esmf@${ESMF_VER}%${COMPILER} ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET
  #spack install -j1 $SPACKOPTS esmf@${ESMF_VER} ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET

  #spack install $SPACKOPTS esmf@${ESMF_VER} ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET
  #spack install $SPACKOPTS esmf  ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET
  # Errors with netcdf.mod, unexpected EOF, maybe corrupted file

  # This is working
  # Did a spack clean and removed ^intel-oneapi-mpi, but but it did not rebuild intel mpi so that probably didn't fix it
  # also removed spack load intel oneapi compilers but that is needed for libimf library maybe for netcdf prereq
  spack install $SPACKOPTS esmf@${ESMF_VER} %${COMPILER} $SPACKTARGET
  # Try using a new netcdf version
  # Can tell mpiifort to use ifx:
  # export FC=ifx
  # export CC=icx
  # export CXX=icpx
  # export I_MPI_CC=icx
  # export I_MPI_CXX=icpx
  # export I_MPI_FC=ifx 

# /mnt/efs/fs1/save/environments/spack/var/spack/cache/_source-cache/archive/ac/acd0b2641587007cc3ca318427f47b9cae5bfd2da8d2a16ea778f637107c29c4.tar.gz
#[+] /usr (external glibc-2.28-xw6lb4vknvfv2xu2vq56ndjocpqslk5b)
#[+] /usr (external glibc-2.28-2uwzqhmprowfl2cm2khpzd2otvfnrprb)

#==> Installing esmf-8.5.0-u4hek76jvy5tklkz3rfde2wtbr3dlu5e [19/19]
#==> Using cached archive: /mnt/efs/fs1/save/environments/spack/var/spack/cache/_source-cache/archive/ac/acd0b2641587007cc3ca318427f47b9cae5bfd2da8d2a16ea778f637107c29c4.tar.gz
#==> Applied patch /mnt/efs/fs1/save/environments/spack/var/spack/repos/builtin/packages/esmf/esmf_cpp_info.patch
#==> esmf: Executing phase: 'edit'
#==> esmf: Executing phase: 'build'
#==> [2025-07-30-22:00:47.876804] '/usr/bin/chmod' '+x' 'scripts/libs.mvapich2f90'
#==> [2025-07-30-22:00:47.879392] 'make' '-j1'

# j1 same error
# clean out /tmp/spack-stage, remove .lock
# next, try removing some externals from /etc/spack/packages
# need to use a newer version of intel oneapi compiler

  # spack --debug install $SPACKOPTS esmf@${ESMF_VER} ^intel-oneapi-mpi@${INTEL_MPI_VER} ^diffutils@3.7 %${COMPILER} $SPACKTARGET
  # spack install $SPACKOPTS esmf@${ESMF_VER} ^intel-oneapi-mpi@${INTEL_MPI_VER} ^diffutils@3.7 %${COMPILER} $SPACKTARGET

  # Install fails with the following
  #COMPILER=oneapi@${ONEAPI_VER}
  #spack install $SPACKOPTS esmf@${ESMF_VER} ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET

  cd $home
}


#-----------------------------------------------------------------------------#
install_fsx_driver () {
    # Run as sudo

    # RedHat EL 8
    # Kernel - uname -r
    # 4.18.0-425.13.1.el8_7.x86_64

    # Install rpm key
    curl https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc -o /tmp/fsx-rpm-public-key.asc

    sudo rpm --import /tmp/fsx-rpm-public-key.asc

    # Add repo
    sudo curl https://fsx-lustre-client-repo.s3.amazonaws.com/el/8/fsx-lustre-client.repo -o /etc/yum.repos.d/aws-fsx.repo

    # Do one of the following:
    kernel=`uname -r`
    echo "Current kernel version is: ${kernel}"


    # If the command returns 4.18.0-553*, you don't need to modify the repository configuration. Continue to the To install the Lustre client procedure.

    ##### If the command returns 4.18.0-513*, you must edit the repository configuration so that it points to the Lustre client for the CentOS, Rocky Linux, and RHEL 8.9 release.
    if [[ $kernel =~ "4.18.0-553" ]]; then
        echo "RHEL 8.10"
	# no change needed
    elif [[ $kernel =~ "4.18.0-513" ]]; then
        echo "RHEL 8.9"
        sudo sed -i 's#/8/#/8.9/#' /etc/yum.repos.d/aws-fsx.repo
    elif [[ $kernel =~ "4.18.0-477" ]]; then
        echo "RHEL 8.8"
        sudo sed -i 's#/8/#/8.8/#' /etc/yum.repos.d/aws-fsx.repo
    elif [[ $kernel =~ "4.18.0-425" ]]; then
        echo "RHEL 8.7"
        sudo sed -i 's#/8/#/8.7/#' /etc/yum.repos.d/aws-fsx.repo
    else
       echo "not sure if any changes to /etc/yum.repos.d/aws-fsx.repo are needed for $kernel"
    fi 

    # If the command returns 4.18.0-477*, you must edit the repository configuration so that it points to the Lustre client for the CentOS, Rocky Linux, and RHEL 8.8 release.

    # If the command returns 4.18.0-425*, you must edit the repository configuration so that it points to the Lustre client for the CentOS, Rocky Linux, and RHEL 8.7 release.

    sudo yum install -y kmod-lustre-client lustre-client
    sudo yum clean all

}


#-----------------------------------------------------------------------------#
install_petsc_intelmpi-spack () {

  . $SPACK_DIR/share/spack/setup-env.sh

  #module use /save/patrick/Cloud-Sandbox/models/modulefiles/
  #module load intel_x86_64.impi_2021.12.1

  COMPILER=oneapi@$ONEAPI_VER
  #module load intel-oneapi-compilers/2023.1.0-gcc-11.2.1-aimw7vu
  #module load intel-oneapi-mpi/2021.12.1-oneapi-2023.1.0-p5npcbi
  #module load hdf5/1.14.3-intel-2021.9.0-jjst2zs
  #module load hdf5/1.14.3-oneapi-2023.1.0-wdcqims

  spack load intel-oneapi-compilers@$ONEAPI_VER
  #spack load intel-oneapi-mpi@$INTEL_MPI_VER%$COMPILER
  #spack load intel-oneapi-runtime@$ONEAPI_VER%$COMPILER

  # COMPILER=intel@${INTEL_COMPILER_VER}
  # gettext-0.22.5 fails to build with intel icc
  #  >> 5440    malloca.c(49): error #3895: expected a comma (the one-argument version of static_assert is not enabled in this mode)
  # spack load intel-oneapi-compilers@${ONEAPI_VER}
  #module load intel-oneapi-compilers
  # try getting this to work, maybe try a previous version of gettext
  # spack install $SPACKOPTS gettext %${COMPILER} $SPACKTARGET
  # icc is deprecated anyways


  ######################################################
  # The PETSc library is required for some FVCOM builds.
  # https://petsc.org/release/install/

  # install with some external packages - spack install petsc +superlu-dist +metis +hypre +hdf5
  #spack install $SPACKOPTS petsc%${COMPILER} +metis +hdf5 cflags='-O3 -march=core-avx2' fflags='-O3 -march=core-avx2' cxxflags='-O3 -march=core-avx2' ^hdf5@1.14.3 ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET 

  #spack install $SPACKOPTS petsc%${COMPILER} cflags='-O3 -march=core-avx2' fflags='-O3 -march=core-avx2' cxxflags='-O3 -march=core-avx2' ^hdf5@1.14.3 ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET 

  spack install $SPACKOPTS petsc%${COMPILER} cflags='-O3 -march=core-avx2' fflags='-O3 -march=core-avx2' cxxflags='-O3 -march=core-avx2' ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET 

}

#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------------#

install_base_rpms () {

  # TODO: refactor into one "install_nco_libs" function
  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  . /usr/share/Modules/init/bash

  # Only do this once
  echo "/usrx/modulefiles" | sudo tee -a ${MODULESHOME}/init/.modulespath

  # gcc/6.5.0  hdf5/1.10.5  netcdf/4.5  produtil/1.0.18 esmf/8.0.0
  libstar=base_rpms.gcc.6.5.0.el7.20200716.tgz

  wrkdir=~/baserpms
  [ -e "$wrkdir" ] && rm -Rf "$wrkdir"
  mkdir -p "$wrkdir"
  cd "$wrkdir"

  wget -nv https://ioos-cloud-sandbox.s3.amazonaws.com/public/libs/$libstar
  tar -xf $libstar
  rm $libstar

  sudo yum -y install python2
  sudo alternatives --set python /usr/bin/python2
  rpmlist='
    produtil-1.0.18-2.el7.x86_64.rpm
  '

  for file in $rpmlist
  do
    sudo rpm -ivh $file --nodeps
  done

  # rm -Rf "$wrkdir"

  cd $home
}

#-----------------------------------------------------------------------------#

install_ncep_rpms () {

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

  # rm -Rf "$wrkdir"

  #sudo yum -y install jasper-devel
  sudo yum -y install jasper-libs

  cd $home
}

#-----------------------------------------------------------------------------#

install_python_modules_user () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  #python3 -m venv /save/$USER/csvenv
  #source /save/$USER/csvenv/bin/activate

  # https://docs-v1.prefect.io/api/0.15.13/

  python3 -m pip install prefect==0.15.13
  python3 -m pip install --upgrade pip
  python3 -m pip install --upgrade wheel
  python3 -m pip install --upgrade dask
  python3 -m pip install --upgrade distributed
  python3 -m pip install --upgrade setuptools_rust  # needed for paramiko
  python3 -m pip install --upgrade paramiko         # needed for dask-ssh
  python3 -m pip install --upgrade haikunator       # memorable Name tags

  # SPACK has problems with botocore newer than below
  python3 -m pip install --upgrade botocore==1.23.46
  # This is the most recent boto3 that is compatible with botocore above
  python3 -m pip install --upgrade boto3==1.20.46

  # Install requirements for plotting module
  # cd ../cloudflow
  # python3 -m pip install --user -r requirements.txt

  # install plotting module
  # python3 setup.py sdist

  # deactivate
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
  # TODO: DOUBLE CHECK: DO NOT OVERWRITE EXISTING KEY
  sudo -u $USER ssh-keygen -t rsa -N ""  -C "mpi-ssh-key" -f /home/$USER/.ssh/id_rsa
  sudo -u $USER cat /home/$USER/.ssh/id_rsa.pub >> /home/$USER/.ssh/authorized_keys

# Prevent SSH prompts when using a local/private address

echo "

Host 127.0.0.1
   CheckHostIP no 
   StrictHostKeyChecking no

Host 10.* 
   CheckHostIP no 
   StrictHostKeyChecking no

Host 192.168.* 
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.16.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.17.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.18.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.19.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.20.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.21.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.22.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.23.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.24.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.25.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.26.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.27.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.28.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.29.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.30.*
   CheckHostIP no 
   StrictHostKeyChecking no

Host 172.31.*
   CheckHostIP no 
   StrictHostKeyChecking no

" | sudo tee -a /etc/ssh/ssh_config

  cd $home
}


#####################################################################

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

  # don't add these if already there

  grep 'alias lsl ls -a' ~/.tcshrc
  if [ $? -eq 1 ]; then
      echo alias lsl ls -al >> ~/.tcshrc
      echo alias lst ls -altr >> ~/.tcshrc
      echo alias h history >> ~/.tcshrc
      echo alias cds cd /save/$USER >> ~/.tcshrc
      echo alias cdc cd /com/$USER >> ~/.tcshrc
      echo alias cdpt cd /ptmp/$USER >> ~/.tcshrc
  fi

  grep 'alias lsl=' ~/.bashrc
  if [ $? -eq 1 ]; then

      echo alias lsl=\'ls -al\' >> ~/.bashrc
      echo alias lst=\'ls -altr\' >> ~/.bashrc
      echo alias h=\'history\' >> ~/.tcshrc
      echo alias cds=\'cd /save/$USER\' >> ~/.bashrc
  fi

  cp system/.vimrc ~/.vimrc

#  git config --global user.name "Patrick Tripp"
#  git config --global user.email "44276748+patrick-tripp@users.noreply.github.com"
#  git commit --amend --reset-author

  #git config user.name "Patrick Tripp"
  #git config user.email "44276748+patrick-tripp@users.noreply.github.com"
  #git config user.name "Michael Lalime"
  #git config user.email "75450912+Michael-Lalime@users.noreply.github.com"

  cd $home
}

