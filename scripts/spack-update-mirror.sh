#!/usr/bin/env bash
#set -x

. environment-vars.sh

#FORCE_OPT='-f'

FORCE_OPT=''
JOBS=4

# New method of trusting key
if [ ! -e $SPACK_KEY ]; then
  wget $SPACK_KEY_URL $SPACK_KEY
  spack gpg trust $SPACK_KEY
  spack gpg list
fi

# Using an s3-mirror for previously built packages
echo "Using SPACK s3-mirror $SPACK_MIRROR"
spack mirror add s3-mirror $SPACK_MIRROR

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

SPEC_LIST='%gcc@11.2.1 %intel@2021.9.0 %oneapi@2023.1.0'

#SPEC_LIST=''

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
    # -f force - overwrite if already in mirror
    spack buildcache push $FORCE_OPT -k $KEY -j $JOBS --only package $SPACK_MIRROR $PKG
  done
done
##################################################################



# These are not publicly redistributable, specify --private
PRIVLIST='

 intel-oneapi-mkl@2023.1.0%oneapi@=2023.1.0/4xphygacsfh5rgmu26oq4gk46ndurhxq
 intel-oneapi-mkl@2023.1.0%oneapi@=2023.1.0/ueed5wr45skemrbctnhqb4chdiew2jti

 intel-oneapi-mkl@2023.1.0%gcc@=11.2.1/5o3qp7opeqmn2cuuxasowddoj4iwzsqr
 intel-oneapi-compilers@2023.1.0%gcc@=11.2.1/3rbcwfi7uuxvqgntbpytpylhmns3vg6l

 intel-oneapi-mpi@2021.12.1%intel@=2021.9.0/6nra3z4zqx5yvtxykhbeueq64da6xvmu

 intel-oneapi-mpi@2021.12.1%oneapi@=2023.1.0/p5npcbixovlsmdotpfqwydphcezlcjgs
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
