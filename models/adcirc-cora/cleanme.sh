#!/usr/bin/env bash

cd /save/ec2-user/adcirc/build || exit 1
make clean

rm -Rf CMake*
rm cmake_install.cmake
rm adc*
rm padcirc
rm -Rf odir*
rm Makefile
ls -altr
