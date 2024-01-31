#!/bin/env bash
# set -x
#scl enable gcc-toolset-11 bash
source scl_source enable gcc-toolset-11

cd /save/environments/spack-stack
source setup.sh
cd envs/ioos-aws-rhel

module use -a /save/environments/modulefiles

module load compiler
module load icc

spack env activate -p .
