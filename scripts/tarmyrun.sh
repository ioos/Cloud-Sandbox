#!/bin/sh

if [ $# -ne 3 ] ; then
  echo "Usage: $0 YYYYMMDD HH cbofs|ngofs etc."
  exit -1
fi

CDATE=$1
CYC=$2
OFS=$3

COMDIR=/com/nos/${OFS}.$CDATE
tmpdir=AWS.${OFS}.${CDATE}

#COMDIR=/com/nos/280cpu.nonesting.ngofs.20191219
#tmpdir=AWS.${OFS}.${CDATE}.280cpu.nonesting

tarfile=${tmpdir}.tgz
tmproot=/ptmp/$USER/tmp
mkdir -p $tmproot/$tmpdir


hhlist='01 06 12 18 24 48'

for hh in $hhlist
do
  echo "copying $hh ..."
  cp -p $COMDIR/nos.${OFS}.fields.f0$hh.$CDATE.t${CYC}z.nc $tmproot/$tmpdir

  if [[ $OFS == "ngofs" ]] ; then
    # nos.ngofs.nestnode.negofs.forecast.20191212.t03z.nc 
    cp -p $COMDIR/nos.ngofs.nestnode.*.forecast.$CDATE.t${CYC}z.nc $tmproot/$tmpdir
  fi

done

# Copy the .in file
cp -p $COMDIR/nos.${OFS}.forecast.$CDATE.t${CYC}z.in $tmproot/$tmpdir

echo "creating tar file ..."
cd $tmproot
tar -czvf $tarfile $tmpdir/

rm -Rf $tmproot/$tmpdir

