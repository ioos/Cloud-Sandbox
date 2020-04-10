#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

# Crontab entry
#30  9   *   *   Thu  nohup /usr/bin/bash -lc $HOME/Cloud-Sandbox/workflow/cron_liveocean.sh < /dev/null > $HOME/locron.out 2>&1

ofs=$1
cyc=$2

echo "PT DEBUG: ofs is : $ofs, cyc is : $cyc"

cd $HOME/Cloud-Sandbox/workflow/workflows

fcst=../jobs/${ofs}.${cyc}z.fcst
plots=../jobs/${ofs}.${cyc}z.diffplots

./nosofs_qops.py $ofs $fcst $plots > $HOME/${ofs}.log 2>&1


