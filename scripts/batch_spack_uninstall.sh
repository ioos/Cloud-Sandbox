#!/bin/env bash

# linux-centos7-haswell
# linux-centos7-skylake_avx512
# gcc@8.5.0
# intel@2021.3.0

#ARCH='linux-centos7-core2'
# ARCH='linux-centos7-skylake_avx512'
#COMP='intel@2021.3.0'
#COMP='gcc@8.5.0'
# COMP='gcc@4.8.5'
COMP='gcc@11.4.1'

# TARGET='skylake_avx512'
# TARGET='haswell'
# TARGET='broadwell'

#PKGS='autoconf@2.69        bzip2@1.0.8    gdbm@1.19                  libiconv@1.16    m4@1.4.19       netcdf-fortran@4.5.3  perl@5.34.0    zlib@1.2.11
#automake@1.16.3      cmake@3.21.1   hdf5@1.10.7                libsigsegv@2.13  ncurses@6.2     numactl@2.0.14        pkgconf@1.7.4
#berkeley-db@18.1.40  diffutils@3.7  intel-oneapi-mpi@2021.3.0  libtool@2.4.6    netcdf-c@4.8.0  openssl@1.1.1k        readline@8.1'

# Spec example:
#      libdwarf %intel ^libelf%gcc
#          libdwarf, built with intel compiler, linked to libelf built with gcc

#for pkg in $PKGS
#do
  #echo "spack uninstall ${pkg}%${COMP} target=$TARGET"
  #spack uninstall -y ${pkg}%${COMP} target=$TARGET
#done

# echo "spack uninstall -a %${COMP} target=$TARGET"

spack uninstall --all -y --dependents %${COMP}
