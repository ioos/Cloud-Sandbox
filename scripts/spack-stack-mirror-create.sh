#!/usr/bin/env bash

#spack-stack.v2.0
SPACK_STACK_VER='v2.0'
SPACK_DIR="/save/environments/spack-stack.${SPACK_STACK_VER}/spack"
SPACK_MIRROR='s3://ioos-sandbox-use2/public/spack-stack/mirror'
#SPACK_KEY_URL='https://ioos-sandbox-use2.s3.amazonaws.com/public/spack/mirror/spack.mirror.gpgkey.pub'
#SPACK_KEY="$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.pub"
JOBS=2
SECRET=$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.secret

spack gpg list

### MAKESURE TO IMPORT/UPLOAD THE PRIVATE KEY FIRST!
if [ ! -e $SECRET ]; then
    echo "Could not find $SECRET"
    exit 1
fi

spack gpg trust $SECRET

spack mirror add s3-spack-stack $SPACK_MIRROR

spack buildcache keys --install --trust --force

# Public Key
KEY=F525C05B06DCA266

# You need to provide at least one package to create a mirror
#PKG='gcc-runtime@11.2.1/wwsew2s'
PKG='bison@3.8.2'
spack mirror create --private -d $SPACK_MIRROR $PKG


spack buildcache push -f -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
#spack buildcache update-index $SPACK_MIRROR

#### spack mirror destroy --mirror-url $SPACK_MIRROR
