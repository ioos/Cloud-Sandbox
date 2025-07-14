#!/usr/bin/env bash
set -e

MODEL_DIR=/save/$USER/necofs/NECOFS_v2.4/hindcast
mkdir -p $MODEL_DIR

HOMEDIR=$(dirname $PWD)
HOMELIBS=$HOMEDIR/libs

VERSION=v4.4.8
REPO=https://github.com/FVCOM-GitHub/FVCOM.git

cd $MODEL_DIR || exit 1
echo $PWD

# Avoid accidental re-clone
if [ ! -d $MODEL_DIR/FVCOM$VERSION ]; then
  git clone $REPO ./FVCOM$VERSION
  cd FVCOM$VERSION
  git checkout $VERSON
else
  echo "it appears FVCOM is already present, not fetching it from the repository"
fi

