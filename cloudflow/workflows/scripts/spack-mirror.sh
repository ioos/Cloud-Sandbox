#!/usr/bin/env bash

SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'

#SPEC='%gcc@4.8'
SPEC='%gcc@8.5'

PKGLIST=`spack find --format "{name}@{version}%{compiler}/{hash}" $SPEC`

for PKG in $PKGLIST
do
  echo $PKG
  spack buildcache create --rebuild-index -a -r --mirror-url $SPACK_MIRROR  $PKG
done
