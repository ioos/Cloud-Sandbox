#!/usr/bin/env bash

#ADCIRCHome=/save/ec2-user/adcirc
#ADCIRCHome=/save/patrick/adcirc

if [ ! $ADCIRCHome ]; then
  echo "Set ADCIRCHome variable before running"
  exit
fi

cd $ADCIRCHome/build || exit 1

make clean

rm -Rf CMake*
rm cmake_install.cmake
rm adc*
rm padcirc
rm -Rf odir*
rm Makefile
ls -altr
