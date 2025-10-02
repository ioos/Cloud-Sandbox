#!/usr/bin/env bash
# git clone the nosofs branch

CURDIR=$PWD

export nosofs_ver=3.5.0
export HOMEnos=/save/$USER/nosofs.$nosofs_ver
export MODULEFILE=intel_x86_64

cd /save/$USER || exit 1

BRANCH='nosofs-eccofs-testing'

if [ ! -d $HOMEnos ]; then
    git clone -b $BRANCH https://github.com/asascience/2022-NOS-Code-Delivery-to-NCO.git $HOMEnos
    if [ $? -ne 0 ]; then
        echo "Unable to clone the repository"
        exit 1
    fi
fi

# Copy the current modulefile
cp $CURDIR/modulefiles/$MODULEFILE $HOMEnos/modulefiles

cd $HOMEnos/sorc

# Clone the ROMS used for eccofs
git clone -b ioos-sandbox-eccofs https://github.com/asascience-open/roms.git ROMS.eccofs

# Build it
# This script can compile all of the nosofs models, only eccofs is specified currently
./ROMS_COMPILE.sh

