#!/usr/bin/env bash

CURDIR=$PWD

# Get the directory name parent to this repository
# e.g. /save/patrick, /save/ec2-user

BASEDIR=$(dirname $(dirname $(dirname $PWD)))
cd $BASEDIR || exit 1

# Get the model and test files, the model is already built
# The full grid will use a different grid mesh

files="2018.ioos_sb.tgz
       adcirc_built.tgz
       cora-runs.tgz"

for f in $files
do
  aws s3 cp s3://ioos-cloud-sandbox/public/cora-adcirc/$f .
  tar -xvf $f
done




