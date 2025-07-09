#!/usr/bin/env bash

SAVE_DIR="/save/$USER"

if [ ! -d $SAVE_DIR ]; then
  echo "Error: $SAVE_DIR does not exist"
  exit 1
fi

BRANCH=v5.13.0

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

