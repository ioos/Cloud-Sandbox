#!/usr/bin/env bash

MODEL_DIR="/save/patrick"

if [ ! -d $MODEL_DIR ]; then
  echo "Error: $MODEL_DIR does not exist"
  exit 1
fi

#BRANCH=v5.13.0
BRANCH=master
BRANCH=87952de300e4f37116f72ba56b52bf86ecb4cca6

SCRIPTS=$PWD

REPO=https://github.com/schism-dev/schism.git
cd $MODEL_DIR

if [ ! -d $MODEL_DIR/schism ]; then
  git clone $REPO 
  if [ $? -ne 0 ]; then
    echo "Unable to clone the repository"
    exit 1
  fi
  cd schism
  git checkout $BRANCH
  git submodule update --init --recursive
else
  echo "it appears schism is already present, not fetching it from the repository"
fi

