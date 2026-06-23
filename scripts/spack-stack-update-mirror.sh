#!/usr/bin/env bash
#set -x

SPACK_STACK_VER='v2.0'
SPACK_DIR="/save/environments/spack-stack.${SPACK_STACK_VER}/spack"
SPACK_MIRROR='s3://ioos-sandbox-use2/public/spack-stack/mirror'
PUB_SPACK_KEY_URL='https://ioos-sandbox-use2.s3.amazonaws.com/public/spack-stack/mirror/spack.mirror.gpgkey.pub'
PUB_SPACK_KEY="$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.pub"
SPACKENV='aws-ioossb-rhel8'

FORCE_OPT=''
#FORCE_OPT='-f'
JOBS=2

cd $SPACK_DIR/../envs
echo $PWD

spack env activate -p $SPACKENV

# New method of trusting key
#if [ ! -e $PUB_SPACK_KEY ]; then
#  wget -o /dev/null -nv -O $PUB_SPACK_KEY $PUB_SPACK_KEY_URL
#  spack gpg trust $PUB_SPACK_KEY
#  spack gpg list
#fi

# Using an s3-mirror for previously built packages
echo "Using SPACK s3-spack-stack $SPACK_MIRROR"
spack mirror add s3-spack-stack $SPACK_MIRROR

#SECRET=$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.secret
SECRET=~/.ssh/spack.mirror.gpgkey.secret

### MAKESURE TO IMPORT/UPLOAD THE PRIVATE KEY FIRST!
if [ ! -e $SECRET ]; then
    echo "Could not find $SECRET"
    exit 1
fi

spack gpg trust $SECRET

# Public Key Name
KEY=F525C05B06DCA266
# 22DC0120263F329AE5C9DA08F525C05B06DCA266

spack buildcache keys --install --trust

#PKGLIST=`spack find --format "{name}@{version}%{compiler}/{hash}"`
PKGLIST=`spack find --format "{name}@{version}/{hash}"`

#PKGLIST="sp@2.5.0/dfj5ys4"

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
