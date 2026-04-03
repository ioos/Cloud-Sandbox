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

#__copyright__ = "Copyright © 2026 Tetra Tech, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

# This has been tested on RHEL8 
#-----------------------------------------------------------------------------#

setup_environment () {

  # TODO: add etc/profile.d customizations - see ./system directory
  # TODO: add .vimrc to ~ to turn off auto-indent - see ./system directory

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  # Some OS releases do not install the docs (man pages) for packages, remove that setting here
  sudo sed -i 's/tsflags=nodocs/# &/' /etc/yum.conf

  # Get rid of subscription manager messages
  sudo subscription-manager config --rhsm.manage_repos=0
  sudo sed -i 's/enabled[ ]*=[ ]*1/enabled=0/g' /etc/yum/pluginconf.d/subscription-manager.conf

  # sudo vi /etc/dnf/plugins/subscription-manager.conf

  ##################
  sudo yum -y update
  #                
  # yum update might update the kernel 
  # and might cause some installs to fail without a reboot first
  # e.g. efa driver
  ##################

  sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
  sudo dnf config-manager --set-enabled codeready-builder-for-rhel-8-rhui-rpms
  sudo dnf install rh-amazon-rhui-client

  sudo yum -y install tcsh
  sudo yum -y install ksh
  sudo yum -y install wget
  sudo yum -y install unzip
  sudo yum -y install time
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
  sudo yum -y install libtool
  sudo dnf -y install Lmod

#[UFS-Sandbox:/etc/alternatives] ec2-user> ls -al
#lrwxrwxrwx.   1 root root   33 Mar 24 17:34 modules.sh -> /usr/share/lmod/lmod/init/profile
#lrwxrwxrwx.   1 root root   30 Mar 24 17:34 modules.fish -> /usr/share/lmod/lmod/init/fish
#lrwxrwxrwx.   1 root root   31 Mar 24 17:34 modules.csh -> /usr/share/lmod/lmod/init/cshrc


  sudo yum -y install tmux
  cp system/tmux.conf ~/.tmux.conf

  sudo yum -y install python3.11-devel

  # Is this safe? It hasn't caused any issues.
  sudo alternatives --set python3 /usr/bin/python3.11
  sudo yum -y install python3.11-pip
  sudo yum -y install jq

  python3 -m pip install boto3

  sudo yum -y install https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
  # sudo systemctl status amazon-ssm-agent

  cliver="2.10.0"
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${cliver}.zip" -o "awscliv2.zip"
  /usr/bin/unzip -q awscliv2.zip
  sudo ./aws/install
  rm awscliv2.zip
  sudo rm -Rf "./aws"

#  sudo yum -y install environment-modules
#  # Only do this once
#  grep "/usr/share/Modules/init/bash" ~/.bashrc >& /dev/null
#  if [ $? -ne 0 ] ; then
#    echo . /usr/share/Modules/init/bash >> ~/.bashrc
#    echo source /usr/share/Modules/init/tcsh >> ~/.tcshrc 
#    . /usr/share/Modules/init/bash
#  fi

#[UFS-Sandbox:/etc/alternatives] ec2-user> echo $MODULESHOME
#/usr/share/lmod/lmod

  # Only do this once
  if [ ! -d /save/environments/modulefiles ] ; then
    sudo mkdir -p /save/environments/modulefiles
    echo "/save/environments/modulefiles" | sudo tee -a ${MODULESHOME}/init/.modulespath
# This is not needed if using Lmod, breaks lua modules
#    echo ". /usr/share/Modules/init/bash" | sudo tee -a /etc/profile.d/custom.sh
#    echo "source /usr/share/Modules/init/csh" | sudo tee -a /etc/profile.d/custom.csh
#    . ~/.bashrc
    cd /save/environments
    sudo chown $USER:$USER .
  fi

  # Add unlimited stack size 
  echo "ulimit -s unlimited" | sudo tee -a /etc/profile.d/custom.sh

  # sudo yum clean {option}
  cd $home

}

#-----------------------------------------------------------------------------#

setup_prefect () {
    # Sets up a local prefect server

    # TODO: Note: there is a docker container that might be better to use
    # TODO: Disable the prefect-server daemon before creating a new AMI

    sudo pip3 install prefect==3.6.8

    # Create system user for prefect daemon
    sudo groupadd --system prefect
    sudo useradd --system --shell /sbin/nologin --gid prefect --comment "Prefect Service Account" prefect
    sudo mkdir -p /save/environments/prefect/.prefect
    sudo chown prefect:prefect /save/environments/prefect/.prefect

    # Create the system daemon
    sudo cp system/prefect-server.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable prefect-server
    sudo systemctl start prefect-server

    #MYIPADDR=`hostname -I | awk '{print $1}'`
    #export PREFECT_API_URL="http://${MYIPADDR}:4200/api"
    # active = "local"
    # [profiles.local]
    # PREFECT_API_URL = "http://127.0.0.1:4200/api"

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

  # /save symlink is created in terraform init_template.tpm

  mkdir /com/$USER
  mkdir /ptmp/$USER

  set +x
  cd $home
}


#-----------------------------------------------------------------------------#

install_spack-stack_prereqs () {

  # Miscellaneous
  sudo yum -y install binutils-devel
  sudo yum -y install git-lfs
  sudo yum -y install bash-completion
  sudo yum -y install xorg-x11-xauth
  sudo yum -y install perl-IPC-Cmd
  sudo yum -y install gettext-devel
  #sudo yum -y install xterm    # really needed? I used it a lot in college, especially for LISP
  #sudo yum -y install texlive  # really needed? bloated! 691MB
  sudo dnf -y install Lmod
  if [ -e /usr/share/lmod/lmod/init/profile ]; then
    sudo alternatives --set modules.sh /usr/share/lmod/lmod/init/profile
  fi

  # All of these are already installed in setup_environment ()
  # Lmod-8.7.65-3.el8.x86_64.rpm
  # sudo yum -y install m4
  # sudo yum -y install wget
  # sudo yum -y install cmake
  # sudo yum -y install git
  # sudo yum -y install bzip2 bzip2-devel
  # sudo yum -y install unzip
  # sudo yum -y install patch
  # sudo yum -y install automake
  # sudo yum -y install bison

  
  
}


#-----------------------------------------------------------------------------#

setup_spack-stack () {

  echo "Running ${FUNCNAME[0]} ..."
  home=$PWD

  cd /save/environments

  SS_BRANCH='aws-ioossb'
  if [ ! -d $SPACKSTACK_DIR ]; then
      #git clone -b release/$SPACKSTACK_VER --recurse-submodules  \

      git clone -b $SS_BRANCH --recurse-submodules  \
          https://github.com/asascience-open/spack-stack.git $SPACKSTACK_DIR

  fi
  cd $SPACKSTACK_DIR
  source setup.sh
  #echo "source /save/environments/spack-stack.v2.0/setup.sh" >> ~/.bashrc

  spack config add "config:install_tree:padded_length:90"

  spack gpg init
  wget -o /dev/null -nv -O $SPACK_KEY $SPACK_KEY_URL
  spack -v gpg trust $SPACK_KEY
  spack -v gpg list

  # Using an s3 mirror for previously built packages
  echo "Using SPACK s3 buildcache $SPACK_MIRROR"
  spack mirror add s3-spack-stack $SPACK_MIRROR

  # spack buildcache keys --install --trust --force
  spack buildcache keys --install --trust
  spack buildcache update-index s3-spack-stack

  # Install Intel Compiler outside of spack-stack environment
  source /opt/intel/oneapi/setvars.sh
  if [ $? -ne 0 ]; then
      echo "WARNING: Intel oneApi Compilers not found!"
  fi

  GCC_MAJOR=${GCC_VER%%.*}
  source /opt/rh/gcc-toolset-$GCC_MAJOR/enable

  # Create the site environment
  spack stack create env --site linux.default --template unified-dev --name aws-ioossb-rhel8 --compiler=oneapi

  cd envs/aws-ioossb-rhel8/
  spack env activate -p .

  ################ environment/site specific ################

  unset SPACK_DISABLE_LOCAL_CONFIG
  export SPACK_SYSTEM_CONFIG_PATH="$PWD/site"

  spack external find --scope system    \
      --exclude bison --exclude meson   \
      --exclude curl --exclude openssl  \
      --exclude openssh --exclude python

  spack external find --scope system grep
  spack external find --scope system wget

  # Note - only needed for generating documentation
  spack external find --scope system texlive

  # Add compilers to the top of site/packages.yaml.
  spack compiler find --scope system

  ################ ################

  export SPACK_DISABLE_LOCAL_CONFIG=true
  unset SPACK_SYSTEM_CONFIG_PATH

  spack config add "packages:mpi:require:['intel-oneapi-mpi@2021.13.0']"
  spack config add "concretizer:targets:granularity:'generic'"
  spack config add "packages:all:target:['x86_64_v3']"

  sed -i 's/tcl/lmod/g' site/modules.yaml
  sed -i 's/tcl/lmod/g' common/modules.yaml

  # echo "spack env activate -p /save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8" >> ~/.bashrc

  cd $home
}


#-----------------------------------------------------------------------------#
build_spack-environment () {

  source /save/environments/spack-stack.v2.0/setup.sh

  source /opt/intel/oneapi/setvars.sh

  GCC_MAJOR=${GCC_VER%%.*}
  source /opt/rh/gcc-toolset-$GCC_MAJOR/enable
  
  cd /save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8
  spack env activate -p .

  # This is in common/packages but was not built with the spec, manually adding it
  # "sp" is a wonderful name - it is one of NCEP's libraries - spectral transformation library, fft related
  spack add sp@2.5.0

  SPACKOPTS="$SPACKOPTS --fail-fast"

  spack concretize --force --fresh 2>&1 | tee log.concretize

  #${SPACK_STACK_DIR}/util/show_duplicate_packages.py
  #spack stack check-preferred-compiler
  #spack stack: error: argument SUBCOMMAND: invalid choice: 'check-preferred-compiler' choose from:

  # The install stops when the terminal times out - use tmux
  spack install $SPACKOPTS 2>&1 | tee log.install
 
  # Setup modules 
  spack module tcl refresh -y
  #spack module lmod refresh -y --delete-tree

  # create setup-meta-modules
  echo "Running spack stack setup-meta-modules ..."
  spack stack setup-meta-modules

}
#-----------------------------------------------------------------------------#



#-----------------------------------------------------------------------------#
setup_rocoto() {
  
  GCC_MAJOR=${GCC_VER%%.*}
  source /opt/rh/gcc-toolset-$GCC_MAJOR/enable

  module use /save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8/modulefiles.tcl/Core
  module load stack-intel-oneapi-compilers/2024.2.1
  module load sqlite/3.46.0

  # Needed for rocoto
  sudo dnf -y install ruby-devel

  cd /save/environments || exit 1
  git clone -b 1.3.7 https://github.com/christopherwharrop/rocoto.git
  cd rocoto
  ./INSTALL

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
install_gcc_toolset_yum() {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  # Also installs tcl environment-modules
  sudo yum -y install gcc-toolset-13-gcc-c++
  sudo yum -y install gcc-toolset-13-gcc-gfortran
  sudo yum -y install gcc-toolset-13-gdb
  sudo yum -y install gcc-toolset-13-gcc-plugin-devel
  sudo dnf install gcc-toolset-13-gcc-plugin-annobin
 
  # source /opt/rh/gcc-toolset-13/enable 

  # Need to reset to Lua for ufs
  echo "NOTICE: For UFS must reset alternatives for modules for Lmod lua modules"
  echo 'Use:  sudo alternatives --config modules.sh'
  if [ -e /usr/share/lmod/lmod/init/profile ]; then
    sudo alternatives --set modules.sh /usr/share/lmod/lmod/init/profile
  fi
  #module --version 
  # Modules based on Lua: Version 8.7.65
  cd $home
}

#-----------------------------------------------------------------------------#

install_spack() {

  echo "Running ${FUNCNAME[0]} ..."
  home=$PWD

  source /opt/rh/gcc-toolset-11/enable

  echo "Installing SPACK in $SPACK_DIR ..."

  if [ ! -d /save ] ; then
    echo "/save does not exst. Setup the paths first."
    return
  fi

  sudo mkdir -p $SPACK_DIR
  sudo chown $USER:$USER $SPACK_DIR
  git clone -q https://github.com/spack/spack.git $SPACK_DIR
  cd $SPACK_DIR
  git checkout -q $SPACK_VER

  # Don't add this if it is already there
  grep "\. $SPACK_DIR/share/spack/setup-env.sh" ~/.bashrc >& /dev/null
  if [ $? -ne 0 ] ; then 
      echo ". $SPACK_DIR/share/spack/setup-env.sh" >> ~/.bashrc
      echo "source $SPACK_DIR/share/spack/setup-env.csh" >> ~/.tcshrc 
  fi

  # Location for overriding default configurations
  sudo mkdir /etc/spack
  sudo chown $USER:$USER /etc/spack
 
  . $SPACK_DIR/share/spack/setup-env.sh

  #echo "DEBUGGING unexpected errors trusting $SPACK_KEY"
  #echo $SPACK_KEY_URL
  #echo $SPACK_KEY
  spack gpg list
  echo "curl -o $SPACK_KEY $SPACK_KEY_URL"
  curl -o $SPACK_KEY $SPACK_KEY_URL
  if [ ! -e $SPACK_KEY ]; then
    echo "ERROR: $SPACK_KEY not downloaded"
  fi
  spack gpg trust $SPACK_KEY
  spack gpg list

  spack config add "config:install_tree:padded_length:73"
  spack config add "modules:default:enable:[tcl]"

  # Using an s3-mirror for previously built packages
  echo "Using SPACK s3-mirror $SPACK_MIRROR"
  spack mirror add s3-mirror $SPACK_MIRROR >& /dev/null
  spack buildcache keys --install --trust
  
  spack compiler find --scope site

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
  echo "WARNING: This will remove everything in $SPACK_DIR, /etc/spack, and ~/.spack"
  echo "Proceed with caution, this action might affect other users"
  read -r -p "Do you want to proceed? (y/N): " response
  case "$response" in
        [Yy]* ) echo "Proceeding ..." ;;
        * ) echo "Operation cancelled. Exiting."; exit;;
  esac

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

}

#-----------------------------------------------------------------------------#
install_intel_oneapi_dnf () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

## Install intel oneapi with dnf
sudo tee /etc/yum.repos.d/oneAPI.repo << EOF
[oneAPI]
name=Intel® oneAPI repository
baseurl=https://yum.repos.intel.com/oneapi
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
EOF

  # sudo rpm --import https://yum.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB
  # sudo yum -y install intel-oneapi-compiler-dpcpp-cpp-and-cpp-classic-2023.1.0.x86_64
  # sudo yum -y install intel-oneapi-compiler-fortran-2023.1.0.x86_64

  mkdir /save/environments/modulefiles

  ONEAPI_MAJOR_MINOR=${ONEAPI_VER%.*}
  sudo dnf install intel-oneapi-compiler-fortran-$ONEAPI_MAJOR_MINOR
  sudo dnf install intel-oneapi-compiler-dpcpp-cpp-$ONEAPI_MAJOR_MINOR
  sudo dnf install intel-oneapi-mkl-devel-$ONEAPI_MAJOR_MINOR
  # sudo dnf install intel-oneapi-mkl-2024.2

  echo "Installed the following at /opt/intel/oneapi:"
  dnf list installed "intel-oneapi-*"

  cd /opt/intel/oneapi/
  sudo ./modulefiles-setup.sh --force --ignore-latest --output-dir=/save/environments/modulefiles/intel

  # Might need to add this back into .bashrc
  module use -a /save/environments/modulefiles
  echo "module use -a /save/environments/modulefiles" >> ~/.bashrc

  cd $home
}

#-----------------------------------------------------------------------------#
install_intel_oneapi_spack () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh 

  source /opt/rh/gcc-toolset-11/enable

  GCC_COMPILER=gcc@$GCC_VER

  spack install $SPACKOPTS intel-oneapi-compilers@${ONEAPI_VER} $SPACKTARGET

  spack compiler add --scope site `spack location -i intel-oneapi-compilers \%${GCC_COMPILER}`/compiler/latest/linux/bin/intel64
  spack compiler add --scope site `spack location -i intel-oneapi-compilers \%${GCC_COMPILER}`/compiler/latest/linux/bin

  cd $home
}



install_intel-oneapi-mkl_spack () {
  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  spack install $SPACKOPTS intel-oneapi-mkl@${ONEAPI_VER}%oneapi@${ONEAPI_VER} $SPACKTARGET

  cd $home
}


#-----------------------------------------------------------------------------#

install_esmf_spack () {

  # Install esmf along with esmf dependencies such as netcdf and hdf5

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  . $SPACK_DIR/share/spack/setup-env.sh

  COMPILER=intel@${INTEL_COMPILER_VER}

  # oneapi mpi spack build option
      # external-libfabric [false]        false, true
      # Enable external libfabric dependency

  #spack install $SPACKOPTS esmf@${ESMF_VER} %${COMPILER} $SPACKTARGET
  spack install $SPACKOPTS esmf@${ESMF_VER} +pnetcdf %${COMPILER} $SPACKTARGET

  # Can tell mpiifort to use ifx:
  # export FC=ifx
  # export CC=icx
  # export CXX=icpx
  # export I_MPI_CC=icx
  # export I_MPI_CXX=icpx
  # export I_MPI_FC=ifx 

  # Install fails with the following
  # COMPILER=oneapi@${ONEAPI_VER}
  # v8.5 and v8.6 build errors with oneapi compilers, use intel classic, maybe try a newer version of oneapi compilers
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

  COMPILER=oneapi@$ONEAPI_VER

  spack load intel-oneapi-compilers@$ONEAPI_VER
  # COMPILER=intel@${INTEL_COMPILER_VER}
  # gettext-0.22.5 fails to build with intel icc
  #  >> 5440    malloca.c(49): error #3895: expected a comma (the one-argument version of static_assert is not enabled in this mode)

  ######################################################
  # The PETSc library is required for some FVCOM builds.
  # https://petsc.org/release/install/

  # install with some external packages - spack install petsc +superlu-dist +metis +hypre +hdf5
  #spack install $SPACKOPTS petsc%${COMPILER} +metis +hdf5 cflags='-O3 -march=core-avx2' fflags='-O3 -march=core-avx2' cxxflags='-O3 -march=core-avx2' ^hdf5@1.14.3 ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET 

  #spack install $SPACKOPTS petsc%${COMPILER} cflags='-O3 -march=core-avx2' fflags='-O3 -march=core-avx2' cxxflags='-O3 -march=core-avx2' ^hdf5@1.14.3 ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET 

  spack install $SPACKOPTS petsc%${COMPILER} cflags='-O3 -march=core-avx2' fflags='-O3 -march=core-avx2' cxxflags='-O3 -march=core-avx2' ^intel-oneapi-mpi@${INTEL_MPI_VER} %${COMPILER} $SPACKTARGET 

}

#-----------------------------------------------------------------------------#
# Install NCEP Libs via Spack

install_nceplibs-spack () {

    . $SPACK_DIR/share/spack/setup-env.sh

    COMPILER=oneapi@$ONEAPI_VER

    package_list='
      prod-util
      bacio
      bufr
      g2
      nemsio
      sigio
      w3emc
      w3nco
      grib-util
    '

    for package in $package_list
    do
      echo "Package: $package"
      spack install $SPACKOPTS ${package}%${COMPILER} $SPACKTARGET
    done

    # source /opt/rh/gcc-toolset-11/enable
    # wgrib2 builds fine with gcc, fails with intel
    COMPILER=gcc@$GCC_VER
    spack install $SPACKOPTS wgrib2%${COMPILER} $SPACKTARGET

    # spack install $SPACKOPTS wgrib2%${COMPILER} ^zlib@1.2.13 $SPACKTARGET # nope
    # zlib is packaged within wgrib2 - sigh
    # spack install $SPACKOPTS wgrib2@3.1.0%${COMPILER} $SPACKTARGET # nope
    # spack install $SPACKOPTS wgrib2%${COMPILER} cflags="-Wno-error" $SPACKTARGET # nope
}


#-----------------------------------------------------------------------------#
install_ncep_libs_spack () {
    return
}


#-----------------------------------------------------------------------------#
install_python_modules_user () {

  echo "Running ${FUNCNAME[0]} ..."

  home=$PWD

  #python3 -m venv /save/$USER/csvenv
  #source /save/$USER/csvenv/bin/activate

  python3 -m pip install prefect==3.6.8
  python3 -m pip install --upgrade pip
  python3 -m pip install --upgrade wheel
  python3 -m pip install --upgrade dask
  python3 -m pip install --upgrade distributed
  python3 -m pip install --upgrade setuptools_rust  # needed for paramiko
  python3 -m pip install --upgrade paramiko         # needed for dask-ssh
  python3 -m pip install --upgrade haikunator       # memorable Name tags

  python3 -m pip install --upgrade botocore==1.40.22
  python3 -m pip install --upgrade boto3==1.40.22

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

  grep 'alias lsl ls -a' ~/.tcshrc >& /dev/null
  if [ $? -ne 0 ]; then
      echo 'alias lsl "ls -al"' >> ~/.tcshrc
      echo 'alias lst "ls -altr"' >> ~/.tcshrc
      echo 'alias h history' >> ~/.tcshrc
      echo 'alias cds "cd /save/$USER"' >> ~/.tcshrc
      echo 'alias cdc "cd /com/$USER"' >> ~/.tcshrc
      echo 'alias cdpt "cd /ptmp/$USER"' >> ~/.tcshrc
      echo 'set prompt="[NEW-IOOS-Sandbox:%~] %n $0> "' >> ~/.tcshrc
  fi

  grep 'alias lsl=' ~/.bashrc
  if [ $? -ne 0 ]; then

      echo 'alias lsl="ls -al"' >> ~/.bashrc
      echo 'alias lst="ls -altr"' >> ~/.bashrc
      echo 'alias h="history"' >> ~/.bashrc
      echo 'alias cds="cd /save/$USER"' >> ~/.bashrc
      echo 'PS1="[NEW-IOOS-Sandbox:\w] \u> "' >> ~/.bashrc
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

