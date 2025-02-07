#!/bin/env bash

# NUID=1001
# GID=1001
# USERNAME="michael.lalime"

# Refer to master spreadsheet for mapping new users
# TODO: improve this process and user management
echo "Need to update script for new user ..."
exit

NUID=2001
GID=2000
USERNAME="yjzhang"

sudo adduser --uid $NUID -m -N --gid $GID $USERNAME
sudo mkdir /save/$USERNAME
sudo chown $USERNAME:$GID
sudo chmod 755 ${USERNAME}

sudo -u $USERNAME ssh-keygen -t rsa -N ""  -C "mpi-ssh-key" -f /home/$USERNAME/.ssh/id_rsa.mpi
sudo -u $USERNAME sh -c "cat /home/$USERNAME/.ssh/id_rsa.mpi.pub >> /home/$USERNAME/.ssh/authorized_keys"
