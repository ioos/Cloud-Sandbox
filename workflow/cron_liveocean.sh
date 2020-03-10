#!/bin/bash

cd $HOME/Cloud-Sandbox/python

fcst=jobs/liveocean.qops.job
plots=jobs/liveocean.qops.plots.job

workflows/liveocean_qops.py $fcst $plots > $HOME/lo.log 2>&1


