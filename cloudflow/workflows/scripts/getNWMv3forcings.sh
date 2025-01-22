#!/bin/bash
#set -x
#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"

if [ $# -lt 4 ] ; then
  echo "Usage: $0 YYYYMMDDHH YYYYMMDDHH MODEL_DIR COMDIR "
  exit 1
fi

SDATE=$1
EDATE=$2
MODEL_DIR=$3
COMDIR=$4

start_year=$(echo "$SDATE" | cut -c 1-4)
start_month=$(echo "$SDATE" | cut -c 5-6)
start_day=$(echo "$SDATE" | cut -c 7-8)
start_hour=$(echo "$SDATE" | cut -c 9-10)

end_year=$(echo "$EDATE" | cut -c 1-4)
end_month=$(echo "$EDATE" | cut -c 5-6)
end_day=$(echo "$EDATE" | cut -c 7-8)
end_hour=$(echo "$EDATE" | cut -c 9-10)

start="$start_hour:00 $start_year-$start_month-$start_day"
end="$end_hour:00 $end_year-$end_month-$end_day"
increment="+1 hours"

# NWM v3 retrospective bucket
bucket=noaa-nwm-retrospective-3-0-pds
domain=CONUS
forcing_dir=FORCING

# Define AWS s3 bucket url pathway based on NWM domain specification
url="https://${bucket}.s3.amazonaws.com/$domain/netcdf/FORCING/"


# Change into the user specified NWM forcing directory to place files into
# for the NWM retorspective simulation
cd $MODEL_DIR/$forcing_dir


# Convert start and end time to full Bash datetime format
# For example, it converts "00:00 2021-04-01" to "Thu Apr 1 00:00:00 GMT 2021"
start=$(date -d "${start}")
end=$(date -d "${end}")

# The below while statement will loop over each date between the start and
# end time. Each loop will increment the date by "+1 hours" (defined above).

# NOTE: The +%s in the first line converts the date to "seconds since 
# EPOC" which makes the comparison between start and end time possible.
# See bottom of page here: https://phoenixnap.com/kb/linux-date-command
while (( $(date -d "${start}" +%s) <= $(date -d "${end}" +%s) )); do
    echo      #< empty echo statement prints a blank line
    #echo Current Loop Date: ${start}
    current_year=$(echo $(date -d "${start}" +%Y))
    current_month=$(echo $(date -d "${start}" +%m))
    current_day=$(echo $(date -d "${start}" +%d))
    current_hour=$(echo $(date -d "${start}" +%H))
    if [[ "$domain" == "CONUS" ]]; then
      nwm_forcing_file=$current_year$current_month$current_day$current_hour"00.LDASIN_DOMAIN1"
    else
      nwm_forcing_file=$current_year$current_month$current_day$current_hour".LDASIN_DOMAIN1"
    fi

    echo Extract NWM $domain retrospective forcing file $nwm_forcing_file
    wget $url$current_year/$nwm_forcing_file

    # Increment the value. This changes the value of `$start` every loop
    # with the next date.
    start=$(date -d "${start} ${increment}")
done
