#!/bin/env bash

NUID=1001
GID=1001
USERNAME="michael.lalime"

#cd /save/home
sudo adduser --uid $NUID -m -N --gid $GID $USERNAME
# sudo chmod 755 ${USERNAME}
