#!/usr/bin/env bash

SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'
JOBS=4

#SPEC='%gcc@4.8'

#SPEC=%intel@2021.3.0
#SPEC='%gcc@8.5'

SPEC_LIST='%intel@2021.3.0 %gcc@8.5 gcc@4.85'

SPEC_LIST='%dpcpp@2023.1.0 %gcc@11.2.1 %intel@2021.9.0 %oneapi@2023.1.0'
#SPEC_LIST='%dpcpp@2023.1.0 %gcc@11.2.1'

### MAKESURE TO IMPORT THE PRIVATE KEY FIRST!
#SECRET=/mnt/efs/fs1/save/environments/spack/opt/spack/gpg/spack.mirror.gpgkey.secret
#spack gpg trust $SECRET
#exit

KEY=F525C05B06DCA266

# Rebuild
PKGLIST=`spack find --format "{name}@{version}%{compiler}/{hash}" $SPEC`

for SPEC in $SPEC_LIST
do
  echo "SPEC: $SPEC"
  for PKG in $PKGLIST
  do
    echo "PACKAGE: $PKG"
    spack buildcache push -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
  done
done
