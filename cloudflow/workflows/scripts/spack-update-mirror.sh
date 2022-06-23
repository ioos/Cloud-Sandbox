#!/usr/bin/env bash

SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'

#SPEC='%gcc@4.8'
#SPEC=%intel@2021.3.0
SPEC='%gcc@8.5'

### MAKE SURE TO IMPORT THE PRIVATE KEY FIRST!

spack config add "config:install_tree:padded_length:128"

# Rebuild
PKGLIST=`spack find --format "{name}@{version}%{compiler}/{hash}" $SPEC`

for PKG in $PKGLIST
do
  echo $PKG
#   spack buildcache create --rebuild-index -a -r --mirror-url $SPACK_MIRROR  $PKG
done
