#!/usr/bin/env bash

#module use -a /save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8/modules/Core
module use -a /save/environments/spack-stack.v2.0/envs/aws-ioossb-rhel8/modules
#### Fing BS! Circular dependency!
#module load stack-intel-oneapi-compilers/2024.2.1
module spider intel-oneapi-compilers/2024.2.1
#module spider intel-oneapi-compilers/2024.2.1

