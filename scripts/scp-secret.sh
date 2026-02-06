#!/usr/bin/env bash
#set -x

# Patrick owns the secret key used for the mirror

. environment-vars.sh

if [ $# -ne 1 ]; then
  echo "Must provide hostname or IP"
  exit 1
fi

host=$1
user='ec2-user'

#SPACK_DIR=/save/environments/spack.v0.22.5
echo $SPACK_DIR

scp -i ~/.ssh/ioos-sandbox.pem ~/OD/SPACK/spack.mirror.gpgkey.secret ${user}@${host}:$SPACK_DIR/opt/spack/gpg

ssh -i ~/.ssh/ioos-sandbox.pem ${user}@${host} "cd $SPACK_DIR/opt/spack/gpg; spack gpg trust spack.mirror.gpgkey.secret"
