#!/usr/bin/env bash

USERNAME=$1
if [[ $USERNAME == "" ]]; then
  echo "Usage $0 username"
  exit 1
fi

DATADIR=/com/secofs/input
mkdir -p $DATADIR
cd $DATADIR || exit 1

URL='https://ccrm.vims.edu/yinglong/NOAA/COOPS/RUN08j_JZ/'

WGET_OPTS='--recursive --no-clobber --continue --no-parent --reject-regex "*\.html\?.*"'
RETRY='--tries=5 --random-wait --waitretry=5'
TIMEOUT='--connect-timeout=5 --read-timeout=30'

wget --user=$USERNAME --ask-password --no-check-certificate $WGET_OPTS $RETRY $TIMEOUT $URL

