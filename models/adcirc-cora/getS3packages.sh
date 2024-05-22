#!/usr/bin/env bash
set -e

cd /save/$USERNAME || exit 1

files="2018.ioos_sb.tgz adcirc_built.tgz cora-runs.tgz"

for f in $files
do
  aws s3 cp s3://ioos-cloud-sandbox/public/cora-adcirc/$f .
  tar -xvf $f
done
