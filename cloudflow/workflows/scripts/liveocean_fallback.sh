#!/bin/bash
set -x

#/data1/parker/LiveOcean/driver/sandbox.txt
#text string would be in the format 2020.10.19
 
#run a cron job in the sandbox every hour that:

#1. Reads a file you maintain someplace (boiler, S3, ftp, etc.).
  #To trigger a forecast, the file should contain today’s date. Otherwise it should be empty, or not today’s date.

#2. Starts the LiveOcean forecast for today if triggered
  #(forcing data and restart file will need to be available on boiler, or an alternate location if there is one.)

#3. History files and any other desired output are sent to an S3 bucket

sshuser='ptripp@boiler.ocean.washington.edu'

remotefldr='/data1/parker/LiveOcean/driver'
# Testing
#remotefldr='/home/ptripp'
# Testing


datefile='sandbox.txt'
TMPDIR='/tmp/LiveOcean'

if [ ! -e $TMPDIR ] ; then
  mkdir $TMPDIR
fi

cd $TMPDIR
scp -p $sshuser:$remotefldr/$datefile .
result=$?
if [ $result -ne 0 ]; then
  echo "Unable to retrieve trigger date from $sshuser:$remotefldr/$datefile"
  exit -1
fi

triggerdate=`cat sandbox.txt`

today=`date +%Y.%m.%d`
echo "Today is $today"

# Check the magic file $datefile to trigger a forecast run
runfcst=0
if [[ $triggerdate == $today ]]; then
  # Only run once for any day
  if [ ! -e "$TMPDIR/launched.$today.txt" ] ; then
    cp $TMPDIR/$datefile $TMPDIR/launched.$today.txt
    echo "Launching LiveOcean forecast for $today"
    runfcst=1
  else 
    echo "Forecast already launched for $today"
    runfcst=0
  fi
else
  echo "There is no LiveOcean trigger for today - $today"
fi


if [ $runfcst -eq 1 ] ; then

  ofs=liveocean
  cyc='00'

  cd $HOME/Cloud-Sandbox/cloudflow

  fcst=job/jobs/${ofs}.${cyc}z.fcst

  ./workflows/nosofs_qops.py $fcst > $HOME/${ofs}.log 2>&1

fi

