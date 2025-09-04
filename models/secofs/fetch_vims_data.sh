#!/usr/bin/env bash

USERNAME=$1
if [[ $USERNAME == "" ]]; then
  echo "Usage $0 username"
  exit 1
fi

wget --user=$USERNAME --ask-password --no-check-certificate --recursive https://ccrm.vims.edu/yinglong/NOAA/COOPS/RUN08j_JZ/

