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

for SPEC in $SPEC_LIST
do
  echo "SPEC: $SPEC"
  echo "-------------------------------------------------------------------------"

  PKGLIST=`spack find --format "{name}@{version}%{compiler}/{hash}" $SPEC`

  # These are not redistributable, specify --private
  #PKGLIST='
      #intel-oneapi-compilers@2023.1.0%gcc@=11.2.1/aimw7vuu3did5zga4raqb4xjbufyermi
      #glibc@2.28%intel@=2021.9.0/2uwzqhmprowfl2cm2khpzd2otvfnrprb
      #intel-oneapi-mpi@2021.12.1%intel@=2021.9.0/6nra3z4zqx5yvtxykhbeueq64da6xvmu
      #'

  echo "Package List: "
  echo "-------------------------------------------------------------------------"
  echo "$PKGLIST"
  echo "-------------------------------------------------------------------------"

  for PKG in $PKGLIST
  do
    echo "PACKAGE: $PKG"
    spack buildcache push -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
    # -f force - overwrite if already in mirror
    #spack --debug buildcache push -f -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
    #spack --debug buildcache push --private -f -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
  done
done
