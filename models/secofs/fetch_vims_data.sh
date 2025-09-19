#!/usr/bin/env bash

# Username and password is provided by VIMS

USERNAME=$1
if [[ $USERNAME == "" ]]; then
  echo "Usage $0 username"
  exit 1
fi

DATADIR=/com/secofs/input
mkdir -p $DATADIR
cd $DATADIR || exit 1

URL='https://ccrm.vims.edu/yinglong/NOAA/COOPS/RUN08j_JZ/'

WGET_OPTS='--recursive --no-clobber --continue --no-parent --reject-regex ".*\.html.*"'
RETRY='--tries=5 --random-wait --waitretry=5'
TIMEOUT='--connect-timeout=5 --read-timeout=30'

wget --user=$USERNAME --ask-password --no-check-certificate $WGET_OPTS $RETRY $TIMEOUT $URL

mv ccrm.vims.edu/yinglong/NOAA/COOPS/RUN08j_JZ/ .
rm -Rf ccrm.vims.edu/
cd RUN08j_JZ | exit 1
rm *index.html*
rm sflux/*index.html*

cd ..

aws s3 sync RUN08j_JZ/ s3://ioos-sandbox-use2/secofs/input/RUN08j_JZ/
