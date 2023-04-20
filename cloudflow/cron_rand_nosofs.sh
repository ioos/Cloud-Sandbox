#!/bin/bash
#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


# Crontab entry example
#30  9   *   *   Thu  nohup /usr/bin/bash -lc $HOME/Cloud-Sandbox/workflow/cron_liveocean.sh < /dev/null > $HOME/locron.out 2>&1

CFHOME=$HOME/Cloud-Sandbox/cloudflow
cd $CFHOME

rand=`$CFHOME/workflows/scripts/random_ofs.py`
ofs=`echo $rand | awk '{print $1}'`
cyc=`echo $rand | awk '{print $2}'`

echo "$ofs $cyc"

fcst=job/jobs/${ofs}.${cyc}z.fcst
#plots=job/jobs/${ofs}.${cyc}z.diffplots
plots=job/jobs/${ofs}.${cyc}z.plots

#echo "Testing, not running: "
#echo "./workflows/nosofs_qops.py $fcst $plots > $HOME/${ofs}.log 2>&1"
nohup ./workflows/nosofs_qops.py $fcst $plots > $HOME/${ofs}.log 2>&1

#nohup ./workflows/nosofs_qops.py job/jobs/dbofs.00z.fcst < /dev/null > $HOME/dbofs.log &
