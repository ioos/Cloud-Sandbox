#!/usr/bin/env bash

SPACK_VER='v0.22.5'
SPACK_DIR="/save/environments/spack.${SPACK_VER}"
SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'
SPACK_KEY_URL='https://ioos-cloud-sandbox.s3.amazonaws.com/public/spack/mirror/spack.mirror.gpgkey.pub'
SPACK_KEY="$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.pub"
JOBS=1

SECRET=$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.secret

### MAKESURE TO IMPORT/UPLOAD THE PRIVATE KEY FIRST!
if [ ! -e $SECRET ]; then
    echo "Could not find $SECRET"
    exit 1
fi

spack gpg trust $SECRET

spack buildcache keys --install --trust --force
#spack buildcache update-index $SPACK_MIRROR

# Public Key
KEY=F525C05B06DCA266

#spack mirror destroy --mirror-url s3://
#spack mirror create --private -d s3://ioos-cloud-sandbox/public/spack/mirror intel-oneapi-compilers@2023.1.0%gcc@=11.2.1/3rbcwfi

PKG='gcc-runtime@11.2.1/wwsew2s'
spack mirror create --private -d s3://ioos-cloud-sandbox/public/spack/mirror $PKG

#spack buildcache push -f -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG


