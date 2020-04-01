#!/bin/bash
#__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
#__license__ = "See LICENSE.txt"
#__email__ = "patrick.tripp@rpsgroup.com"

cd $HOME/Cloud-Sandbox/python

fcst=job/jobs/liveocean.qops.job
plots=job/jobs/liveocean.qops.plots.job

workflows/liveocean_qops.py $fcst $plots > $HOME/lo.log 2>&1


