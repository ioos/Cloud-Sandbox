#!/usr/bin/env bash

# ssh -i ~/.ssh/ioos-sandbox.pem ec2-user@ec2-3-128-236-96.us-east-2.compute.amazonaws.com
host='ec2-3-130-117-202.us-east-2.compute.amazonaws.com'

user='ec2-user'

scp -p -i ~/.ssh/ioos-sandbox.pem ~/OD/SPACK/spack.mirror.gpgkey.secret ${user}@${host}:/save/environments/spack/opt/spack/gpg

ssh -i ~/.ssh/ioos-sandbox.pem ${user}@${host} 'cd /save/environments/spack/opt/spack/gpg; spack gpg trust spack.mirror.gpgkey.secret'
