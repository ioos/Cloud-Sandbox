#!/usr/bin/env bash
# set -x

SPACK_DIR='/save/environments/spack'
SPACK_MIRROR=s3://ioos-cloud-sandbox/public/spack/mirror
SPACK_KEY_URL='https://ioos-cloud-sandbox.s3.amazonaws.com/public/spack/mirror/spack.mirror.gpgkey.pub'
SPACK_KEY="$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.pub"
JOBS=4

echo "Using SPACK s3-mirror $SPACK_MIRROR"
spack mirror add s3-mirror $SPACK_MIRROR

spack buildcache keys --install --trust --force
spack buildcache update-index $SPACK_MIRROR

#SPEC='%gcc@4.8'
#SPEC=%intel@2021.3.0
#SPEC='%gcc@8.5'

SPEC_LIST='%gcc@11.2.1 %intel@2021.9.0'

SECRET=/mnt/efs/fs1/save/environments/spack/opt/spack/gpg/spack.mirror.gpgkey.secret

### MAKESURE TO IMPORT/UPLOAD THE PRIVATE KEY FIRST!
if [ ! -e $SECRET ]; then
    echo "Could not find $SECRET"
    exit 1
fi

spack gpg trust $SECRET

# Public Key
KEY=F525C05B06DCA266

# Rebuild
PKGLIST=`spack find --format "{name}@{version}%{compiler}/{hash}" $SPEC`
echo "$PKGLIST"

for SPEC in $SPEC_LIST
do
  echo "SPEC: $SPEC"
  for PKG in $PKGLIST
  do
    echo "PACKAGE: $PKG"
    spack buildcache push -f -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
  done
done
