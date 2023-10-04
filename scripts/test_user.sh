#!/bin/env bash

NUID=1002
GID=1001
USERNAME=""

#cd /save/home
sudo adduser --uid $NUID -m -N --gid $GID $USERNAME
#sudo chmod 755 ${USERNAME}
