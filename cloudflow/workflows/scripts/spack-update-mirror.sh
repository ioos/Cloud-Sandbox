#!/usr/bin/env bash

SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'

#SPEC='%gcc@4.8'

#SPEC=%intel@2021.3.0
#SPEC='%gcc@8.5'

SPEC_LIST='%intel@2021.3.0 %gcc@8.5'

### MAKE SURE TO IMPORT THE PRIVATE KEY FIRST!
# SECRET=~/spack.mirror.gpgkey.secret
# spack gpg trust $SECRET

# Rebuild
PKGLIST=`spack find --format "{name}@{version}%{compiler}/{hash}" $SPEC`

for SPEC in $SPEC_LIST
do
  echo "SPEC: $SPEC"
  for PKG in $PKGLIST
  do
    echo "PACKAGE: $PKG"
    spack buildcache create --rebuild-index -a -r --mirror-url $SPACK_MIRROR  $PKG
  done
done
