#!/usr/bin/env bash
#set -x

SPACK_STACK_VER='v2.0'
SPACK_DIR="/save/environments/spack-stack.${SPACK_STACK_VER}/spack"
SPACK_MIRROR='s3://ioos-sandbox-use2/public/spack-stack/mirror'
SPACK_KEY_URL='https://ioos-sandbox-use2.s3.amazonaws.com/public/spack-stack/mirror/spack.mirror.gpgkey.pub'
SPACK_KEY="$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.pub"

FORCE_OPT=''
#FORCE_OPT='-f'
JOBS=8

# New method of trusting key
if [ ! -e $SPACK_KEY ]; then
  wget $SPACK_KEY_URL $SPACK_KEY
  spack gpg trust $SPACK_KEY
  spack gpg list
fi

# Using an s3-mirror for previously built packages
echo "Using SPACK s3-spack-stack $SPACK_MIRROR"
spack mirror add s3-spack-stack $SPACK_MIRROR

SECRET=$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.secret

### MAKESURE TO IMPORT/UPLOAD THE PRIVATE KEY FIRST!
if [ ! -e $SECRET ]; then
    echo "Could not find $SECRET"
    exit 1
fi

# Public Key
KEY=F525C05B06DCA266

spack buildcache keys --install --trust
spack buildcache update-index $SPACK_MIRROR

  #PKGLIST=`spack find --format "{name}@{version}%{compiler}/{hash}"`
  PKGLIST=`spack find --format "{name}@{version}/{hash}"`

  echo "Package List: "
  echo "-------------------------------------------------------------------------"
  echo "$PKGLIST"
  echo "-------------------------------------------------------------------------"

  for PKG in $PKGLIST
  do
    echo "PACKAGE: $PKG"
    # -f force - overwrite if already in mirror
    spack buildcache push --private $FORCE_OPT -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
  done
##################################################################



# These are not publicly redistributable, specify --private
PRIVLIST='

'

# PRIVLIST=''

for PKG in $PRIVLIST
do
   echo "PRIVATE PACKAGE: $PKG"
    # -f force - overwrite if already in mirror
    spack buildcache push --private $FORCE_OPT -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
done

echo "Updating the cache index - might take a while ..."
spack buildcache update-index $SPACK_MIRROR
echo "Done"
