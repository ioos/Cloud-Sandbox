#!/bin/bash

if [ $# -ne 2 ] ; then
  echo "Usage: $0 YYYYMMDD COMROT"
  exit 1
fi

CDATE=$1
COMROT=$2

#CDATE=20110827
if [[ $CDATE != "20110827" ]]; then
    echo "Only Hurricane Irene test case is currently supported"
    exit 2
fi

if [ -d $COMROT ]; then
 list=`ls -1 $COMROT | wc -l`
 if [ $list -gt 4 ] ; then
   echo "It looks like ICs already exist. Remove the files to force the download... skipping."
   exit 0
 fi
fi

mkdir -p $COMROT
cd $COMROT

url=https://ioos-cloud-sandbox.s3.amazonaws.com/public/wrfroms
forcing_file=wrfroms.forcings.${CDATE}.tgz

echo "Retrieving forcing from S3 ..."
curl -o $forcing_file $url/$forcing_file

echo "Download completed."
echo "Un-tarring tar file ..."
tar -xvf $forcing_file
rm $forcing_file
echo "Completed. All required inputs are at $COMROT"

