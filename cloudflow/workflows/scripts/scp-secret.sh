#!/usr/bin/env bash

host='ec2-3-132-69-122.us-east-2.compute.amazonaws.com'
user='centos'

scp -p -i ioos-sandbox.pem ~/RPS/SPACK/spack.mirror.gpgkey.secret ${user}@${host}:/save/environments/spack/opt/spack/gpg

ssh -i ioos-sandbox.pem ${user}@${host} 'cd /save/environments/spack/opt/spack/gpg; spack gpg trust spack.mirror.gpgkey.secret'
