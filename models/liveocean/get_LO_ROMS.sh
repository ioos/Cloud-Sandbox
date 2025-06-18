#!/bin/bash

TOPDIR=${PWD}

# LO:
LOCOMMIT=197a799cfeeae06cac0981b1e2c80da117f9abb4

# Parker's LO_roms_user:
# LORUCOMMIT=

# LO_roms_user RPS fork
LORUCOMMIT=1d3e200e023475aea821e4dbf79bcb158bd84767

# LO_roms_source_alt
LORSACOMMIT=a6851a669fa58167b43c5263132464ac7e5fe9de

# ROMS
ROMSSVNVERSION=1205
ROMSGITVERSION=fb0275c5

echo "cloning the LiveOcean ROMS git repositories"

git clone https://github.com/parkermac/LO.git
cd LO
git checkout $LOCOMMIT
cd $TOPDIR

# RPS fork with build fix
git clone https://github.com/asascience/LO_roms_user.git
cd LO_roms_user/
git checkout $LORUCOMMIT
cd $TOPDIR

git clone https://github.com/parkermac/LO_roms_source_alt.git
cd LO_roms_source_alt
git checkout $LORSACOMMIT
cd $TOPDIR

# ROMS SRC git
git clone https://github.com/myroms/roms.git ./LO_roms_source_git
cd LO_roms_source_git
git checkout $ROMSGITVERSION

