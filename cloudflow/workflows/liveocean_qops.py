#!/usr/bin/env python3
import collections
import time
import logging
import os
import sys
import re
from signal import signal, SIGINT
from pathlib import Path

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.utils import romsUtil as util
from cloudflow.workflows import flows

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

curdir = os.path.dirname(os.path.abspath(__file__))
homedir = Path.home()

fcstconf = f'{curdir}/../cluster/configs/liveocean.qops.fcst'
postconf = f'{curdir}/../cluster/configs/liveocean.qops.post'

# This is used for obtaining liveocean forcing data
# LiveOcean users need to obtain credentials from UW
sshuser = 'ptripp@boiler.ocean.washington.edu'

log = logging.getLogger('lo_qops_timing')
log.setLevel(logging.DEBUG)
ch = logging.FileHandler(f"{homedir}/lo_qops_forecast.log")
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter(' %(asctime)s  %(levelname)s | %(message)s')
ch.setFormatter(formatter)
log.addHandler(ch)

def handler(signal_received, frame):
    print('SIGINT or CTRL-C detected. Exiting gracefully')
    raise signal.FAIL()

def main():

    signal(SIGINT, handler)

    lenargs = len(sys.argv) - 1
    joblist = []

    idx = 1
    while idx <= lenargs:
        ajobfile = os.path.abspath(sys.argv[idx])
        joblist.append(ajobfile)
        idx += 1

    flowdeq = collections.deque()

    for jobfile in joblist:
        jobdict = util.readConfig(jobfile)
        jobtype = jobdict["JOBTYPE"]
        print('JOBTYPE: ', jobtype)

        if re.search("forecast", jobtype):
        # Add the forecast flow
            fcstflow = flows.fcst_flow(fcstconf, jobfile, sshuser)
            flowdeq.appendleft(fcstflow)

        # Add the plot flow
        elif jobtype == "plotting":
            plotflow = flows.plot_flow(postconf, jobfile)
            flowdeq.appendleft(plotflow)

        # Add the diff plot flow
        elif jobtype == "plotting_diff":
            diffplotflow = flows.diff_plot_flow(postconf, jobfile, sshuser)
            flowdeq.appendleft(diffplotflow)

        else:
            print(f"jobtype: {jobtype} is not supported")
            sys.exit()

    qlen = len(flowdeq)
    idx = 0


    # Run all of the flows in the queue
    while idx < qlen:
        aflow = flowdeq.pop()
        idx += 1

        if re.search("fcst", aflow.name):
            start_time = time.time()
            log.info("Forecast flow starting")

        state = aflow.run()

        # Stop if the flow failed
        if state.is_successful():
            if re.search("fcst", aflow.name):
                end_time = time.time()
                elapsed = end_time - start_time
                mins = elapsed / 60.0
                hrs = mins / 60.0
                log.info(f"Elapsed Time: {hrs:.3f} hours (4 nodes)")
            continue
        else:
            log.error(f"{aflow.name} failed")
            break


#####################################################################


if __name__ == '__main__':
    main()
