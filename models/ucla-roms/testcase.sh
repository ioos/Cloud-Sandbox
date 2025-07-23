#!/bin/bash

export HOMEroms=/save/$USER/ucla-roms

export ROMS_ROOT=$HOMEroms

cp compile.sh ${ROMS_ROOT}/Examples/Rivers_real/.
cd ${ROMS_ROOT}/Examples/Rivers_real/.
./compile.sh

