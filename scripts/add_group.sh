#!/bin/env bash

# Refer to master spreadsheet for adding groups and users
# TODO: improve this process and user management
echo "Need to update script for new group ..."
exit

GID=2000
GROUPNAME="SECOFS"
sudo groupadd --gid $GID $GROUPNAME
