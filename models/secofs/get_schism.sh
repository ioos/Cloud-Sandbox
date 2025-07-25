#!/usr/bin/env bash

MODEL_DIR="/save/$USER"

if [ ! -d $MODEL_DIR ]; then
  echo "Error: $MODEL_DIR does not exist"
  exit 1
fi


#https://github.com/jduckerOWP/schism/tree/v5.13.0_NOS_Sandbox
#https://github.com/jduckerOWP/schism.git

REPO=https://github.com/jduckerOWP/schism.git
BRANCH=v5.13.0_NOS_Sandbox

#REPO=https://github.com/schism-dev/schism.git
#BRANCH=v5.13.0

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

