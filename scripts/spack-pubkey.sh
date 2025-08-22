  . environment-vars.sh

  SPACK_MIRROR='s3://ioos-cloud-sandbox/public/spack/mirror'
  SPACK_KEY_URL='https://ioos-cloud-sandbox.s3.amazonaws.com/public/spack/mirror/spack.mirror.gpgkey.pub'
  SPACK_KEY="$SPACK_DIR/opt/spack/gpg/spack.mirror.gpgkey.pub"

  # New method of trusting key
  if [ ! -e $SPACK_KEY ]; then
    wget $SPACK_KEY_URL -O $SPACK_KEY
  fi
  spack gpg trust $SPACK_KEY
  spack gpg list

  # Using an s3-mirror for previously built packages
  echo "Using SPACK s3-mirror $SPACK_MIRROR"

  # echo "Ignore 'Mirror ... already exists' error"
  spack mirror add s3-mirror $SPACK_MIRROR >& /dev/null
  spack buildcache keys --install --trust

  echo Done

