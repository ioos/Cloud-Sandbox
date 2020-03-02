#!/bin/bash


module load gcc
module load mpi

export CC=mpicc
export CXX=mpicxx
export prefix=/save/tools/osu-benchmarks

./configure --prefix=$prefix
make
make install


