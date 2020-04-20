#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

# Crontab entry
#30  9   *   *   Thu  nohup /usr/bin/bash -lc $HOME/Cloud-Sandbox/workflow/cron_liveocean.sh < /dev/null > $HOME/locron.out 2>&1

if [ $# -ne 2 ] ; then
  echo "Usage $0 ofs hh"
  exit 1
fi

ofs=$1
cyc=$2

cd $HOME/Cloud-Sandbox/cloudflow

fcst=job/jobs/${ofs}.${cyc}z.fcst
plots=job/jobs/${ofs}.${cyc}z.diffplots

nohup ./workflows/nosofs_qops.py $fcst $plots > $HOME/${ofs}.log 2>&1


