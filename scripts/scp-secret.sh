#!/usr/bin/env bash

# Patrick owns the secret key used for the mirror

if [ $# -ne 1 ]; then
  echo "Must provide hostname or IP"
  exit 1
fi

host=$1
user='ec2-user'

scp -p -i ~/.ssh/ioos-sandbox.pem ~/OD/SPACK/spack.mirror.gpgkey.secret ${user}@${host}:/save/environments/spack/opt/spack/gpg

ssh -i ~/.ssh/ioos-sandbox.pem ${user}@${host} 'cd /save/environments/spack/opt/spack/gpg; spack gpg trust spack.mirror.gpgkey.secret'
