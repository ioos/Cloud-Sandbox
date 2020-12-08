#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

# Crontab entry
#30  9   *   *   Thu  nohup /usr/bin/bash -lc $HOME/Cloud-Sandbox/workflow/cron_liveocean.sh < /dev/null > $HOME/locron.out 2>&1

ofs=liveocean
cyc='00'

cd $HOME/Cloud-Sandbox/cloudflow

fcst=job/jobs/${ofs}.${cyc}z.fcst

nohup ./workflows/nosofs_qops.py $fcst > $HOME/${ofs}.log 2>&1

