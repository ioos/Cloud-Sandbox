#!/bin/bash

gccdir=/home/centos/gcc-7.4.0

. /usr/share/Modules/init/bash
module load gcc/6.5.0

prefix=/usrx/gcc/7.4.0
confopts="--enable-ld --disable-multilib"
#$gccdir/configure $confopts --prefix=$prefix
#make -j 4
make install
