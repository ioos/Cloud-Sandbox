#!/bin/env bash
#set -x

TOPDIR=${PWD}

./get_LO_ROMS.sh
cd $TOPDIR

./LO_COMPILE.sh
cd $TOPDIR

./get_LiveOcean_data.sh
cd $TOPDIR

