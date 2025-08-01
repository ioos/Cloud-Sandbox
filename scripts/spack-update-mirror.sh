#!/usr/bin/env bash
# set -x

SPACK_DIR='/save/environments/spack'
SPACK_MIRROR=s3://ioos-cloud-sandbox/public/spack/mirror
SPACK_KEY_URL='https://ioos-cloud-sandbox.s3.amazonaws.com/public/spack/mirror/spack.mirror.gpgkey.pub'
SPACK_KEY="$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.pub"
JOBS=6

echo "Using SPACK s3-mirror $SPACK_MIRROR"
spack mirror add s3-mirror $SPACK_MIRROR

spack buildcache keys --install --trust --force
spack buildcache update-index $SPACK_MIRROR

#SPEC_LIST='%gcc@11.2.1 %intel@2021.9.0 %oneapi@2023.1.0'
#SPEC_LIST='%gcc@11.2.1'
#SPEC_LIST='%intel@2021.9.0'
#SPEC_LIST='%oneapi@2023.1.0'
SPEC_LIST=''

SECRET=/mnt/efs/fs1/save/environments/spack/opt/spack/gpg/spack.mirror.gpgkey.secret

### MAKESURE TO IMPORT/UPLOAD THE PRIVATE KEY FIRST!
if [ ! -e $SECRET ]; then
    echo "Could not find $SECRET"
    exit 1
fi

# Public Key
KEY=F525C05B06DCA266

for SPEC in $SPEC_LIST
do
  echo "SPEC: $SPEC"
  echo "-------------------------------------------------------------------------"

  PKGLIST=`spack find --format "{name}@{version}%{compiler}/{hash}" $SPEC`

  echo "Package List: "
  echo "-------------------------------------------------------------------------"
  echo "$PKGLIST"
  echo "-------------------------------------------------------------------------"

  for PKG in $PKGLIST
  do
    echo "PACKAGE: $PKG"
    #spack buildcache push -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
    # -f force - overwrite if already in mirror
    spack buildcache push -f -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
  done
done
##################################################################


# These are not publicly redistributable, specify --private
PRIVLIST='
 intel-oneapi-compilers@2023.1.0%gcc@=11.2.1/3rbcwfi7uuxvqgntbpytpylhmns3vg6l
 intel-oneapi-mpi@2021.12.1%intel@=2021.9.0/6nra3z4zqx5yvtxykhbeueq64da6xvmu
 intel-oneapi-mkl@2023.1.0%oneapi@=2023.1.0/5hqrhtxoxhtjdlujxekchcwaakdvb2kz
 intel-oneapi-mpi@2021.12.1%oneapi@=2023.1.0/p5npcbixovlsmdotpfqwydphcezlcjgs
'

# These packages can not be pushed to a mirror for some reason and have to be built every time
# findutils

PRIVLIST=''

for PKG in $PRIVLIST
do
   echo "PACKAGE: $PKG"
    # -f force - overwrite if already in mirror
    #spack --debug buildcache push -f -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
    spack buildcache push --private -f -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
done

echo "Updating the cache index - might take a while ..."
spack buildcache update-index $SPACK_MIRROR
echo "Done"
