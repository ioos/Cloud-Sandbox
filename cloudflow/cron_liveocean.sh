#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

# Crontab entry
#30  9   *   *   Thu  nohup /usr/bin/bash -lc $HOME/Cloud-Sandbox/workflow/cron_liveocean.sh < /dev/null > $HOME/locron.out 2>&1


cd $HOME/Cloud-Sandbox/workflow/workflows

fcst=../jobs/liveocean.qops.fcst
plots=../jobs/liveocean.qops.diffplots

./liveocean_qops.py $fcst $plots > $HOME/lo.log 2>&1


