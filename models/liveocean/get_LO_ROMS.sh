#!/bin/bash

TOPDIR=${TOPDIR:-${PWD}}
MODEL_DIR=${MODEL_DIR:-/save/$USER/liveocean}

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

cd $MODEL_DIR
if [ -e LO ]; then
    echo "LO already exists, not cloning it." 
else
    git clone https://github.com/parkermac/LO.git
    cd LO
    git checkout $LOCOMMIT
fi


# RPS fork with build fix
cd $MODEL_DIR
if [ -e LO_roms_user ]; then
    echo "LO_roms_user already exists, not cloning it." 
else
    git clone https://github.com/asascience/LO_roms_user.git
    cd LO_roms_user/
    git checkout $LORUCOMMIT
fi


cd $MODEL_DIR
if [ -e LO_roms_source_alt ]; then
    echo "LO_roms_source_alt already exists, not cloning it." 
else
    git clone https://github.com/parkermac/LO_roms_source_alt.git
    cd LO_roms_source_alt
    git checkout $LORSACOMMIT
fi


# ROMS SRC git
cd $MODEL_DIR
if [ -e LO_roms_source_git ]; then
    echo "LO_roms_source_git already exists, not cloning it." 
else
    git clone https://github.com/myroms/roms.git ./LO_roms_source_git
    cd LO_roms_source_git
    git checkout $ROMSGITVERSION
fi

cd $TOPDIR
