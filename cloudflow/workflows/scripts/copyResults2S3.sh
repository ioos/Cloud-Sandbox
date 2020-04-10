#!/bin/sh -x

if [[ $# -ne 3 ]] ; then
  echo Usage: $0 COMDIR cdate cyc
  echo "Example: $0 /noscrub/com/nos 20191021 00"
  exit 1
fi

COMDIR=$1
cdate=$2
cyc=$3

bucket=ioos-cloud-sandbox/cbofs-output

cd $COMDIR/cbofs.$cdate

flist=`ls -1 nos.cbofs.fields.f???.${cdate}.t${cyc}z.nc`

for file in $flist
do
  # echo $file
  # aws s3 cp nos.cbofs.fields.f004.20191021.t00z.nc s3:://ioos-cloud-sandbox/cbofs-output/cbofs.20191021/
  # aws s3 cp $file $bucket/cbofs.$cdate/
  # echo aws s3 cp $file s3://$bucket/cbofs.$cdate/
  aws s3 cp $file s3://$bucket/cbofs.$cdate/
done


