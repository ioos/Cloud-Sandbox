#!/bin/bash
#set -e

if [ -n "$1" ] ; then
	#echo Usage: sh OwiTimes.sh \<owifile\>
	#exit 1
	files=$1
else
	files=$(ls *.22?) 
	if [ -z "$files" ] ; then
		files=`ls *.{pre,win}`
	fi
	if [ -z "$files" ] ; then
		echo no files to check.
		exit
	fi
fi

Secs="00"

for f in $files; do

	h=`head -n 1 $f`
	StartTime=`echo $h | awk '{print $(NF-1)}' `
	#echo $StartTime
	StartTimeY=${StartTime:0:4}
	StartTimeM=${StartTime:4:2}
	StartTimeD=${StartTime:6:2}
	StartTimeH=${StartTime:8:2}
	StartTimeMn=${StartTime:10:2}
	if [ -z $StartTimeMn ] ; then
		StartTimeMn="00"
	fi
	StartDateTime="$StartTimeY-$StartTimeM-$StartTimeD $StartTimeH:$StartTimeMn:$Secs"
	StartTimeSecs=`date --utc --date "$StartDateTime" +%s`
	#echo "$StartTimeY : $StartTimeM : $StartTimeD : $StartTimeH : $StartTimeMn : $StartDateTime : $StartTimeSecs"

	EndTime=`echo $h | awk '{print $NF}' `
	#echo $EndTime
	EndTimeY=${EndTime:0:4}
	EndTimeM=${EndTime:4:2}
	EndTimeD=${EndTime:6:2}
	EndTimeH=${EndTime:8:2}
	EndTimeMn=${EndTime:10:2}
	if [ -z $EndTimeMn ] ; then
		EndTimeMn="00"
	fi
	EndDateTime="$EndTimeY-$EndTimeM-$EndTimeD $EndTimeH:$EndTimeMn:$Secs"
	EndTimeSecs=`date --utc --date "$EndDateTime" +%s`
	#echo "$EndTimeY : $EndTimeM : $EndTimeD : $EndTimeH : $EndTimeMn : $EndDateTime : $EndTimeSecs"

	rnday=`echo "scale=6; ($EndTimeSecs - $StartTimeSecs)/86400" | bc`

	Time1=`grep -m 1 iLat $f  | awk -F= '{print $NF}'`
	Time1Y=${Time1:0:4}
	Time1M=${Time1:4:2}
	Time1D=${Time1:6:2}
	Time1H=${Time1:8:2}
	Time1Mn=${Time1:10:2}
	DateTime1="$Time1Y-$Time1M-$Time1D $Time1H:$Time1Mn:$Secs"
	Time1Secs=`date --utc --date "$DateTime1" +%s`

	Time2=`grep -m 2 iLat $f | head -n 2 | tail -n 1 | awk -F= '{print $NF}'`
	Time2Y=${Time2:0:4}
	Time2M=${Time2:4:2}
	Time2D=${Time2:6:2}
	Time2H=${Time2:8:2}
	Time2Mn=${Time2:10:2}
	DateTime2="$Time2Y-$Time2M-$Time2D $Time2H:$Time2Mn:$Secs"
	Time2Secs=`date --utc --date "$DateTime2" +%s`

	dt=`echo "scale=6;($Time2Secs - $Time1Secs)/60" | bc`

	echo $f $StartTime $EndTime $dt $rnday
done
