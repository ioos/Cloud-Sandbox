#!/usr/bin/env bash

cd /save/$USER || exit 1

BRANCH=v5.13.0
MODEL_DIR=/save/$USER/schism
REPO=https://github.com/schism-dev/schism.git

if [ ! -d $MODEL_DIR ]; then
    git clone -b $BRANCH $REPO $MODEL_DIR
    if [ $? -ne 0 ]; then
        echo "Unable to clone the repository"
        exit 1
    fi
fi

