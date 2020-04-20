#!/usr/bin/env python3
print(f"file: {__file__} | name: {__name__} | package: {__package__}")

import collections
import os
import sys
import re
from signal import signal, SIGINT
from pathlib import Path

if os.path.abspath('.') not in sys.path:
    sys.path.append(os.path.abspath('.'))

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

# Local dependencies
from cloudflow.utils import romsUtil as util
from cloudflow.workflows import flows

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

# Set these for specific use
curdir = os.path.dirname(os.path.abspath(__file__))
homedir = Path.home()

fcstconf = f'{curdir}/../cluster/configs/nosofs.config'
postconf = f'{curdir}/../cluster/configs/post.config'

# This is used for obtaining liveocean forcing data
# Users need to obtain credentials from UW
sshuser = 'ptripp@boiler.ocean.washington.edu'

log = logging.getLogger('qops_timing')
log.setLevel(logging.DEBUG)
ch = logging.FileHandler(f"{homedir}/qops_forecast.log")
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter(' %(asctime)s  %(levelname)s | %(message)s')
ch.setFormatter(formatter)
log.addHandler(ch)

def handler(signal_received, frame):
    print('SIGINT or CTRL-C detected. Exiting gracefully')
    raise signal.FAIL()


def main():
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

        # Add the forecast flow
        if re.search("forecast", jobtype):
            OFS = jobdict["OFS"]
            fcstdict = util.readConfig(fcstconf)
            nodetype = fcstdict["nodeType"]
            nodecnt = fcstdict["nodeCount"]
            fcstflow = flows.fcst_flow(fcstconf, jobfile, sshuser)
            flowdeq.appendleft(fcstflow)

        # Add the plot flow
        elif jobtype == "plotting":
            plotflow = flows.plot_flow(postconf, jobfile)
            flowdeq.appendleft(plotflow)

        # Add the diff plot flow
        elif jobtype == "plotting_diff":
            diffplotflow = flows.diff_plot_flow(postconf, jobfile)
            flowdeq.appendleft(diffplotflow)

        else:
            print(f"jobtype: {jobtype} is not supported")
            sys.exit()

    qlen = len(flowdeq)
    idx = 0

    while idx < qlen:
        aflow = flowdeq.pop()
        idx += 1

        if re.search("fcst", aflow.name):
            start_time = time.time()
            log.info(f"Forecast flow starting - {OFS}")

        state = aflow.run()

        if state.is_successful():
            if re.search("fcst", aflow.name):
                end_time = time.time()
                elapsed = end_time - start_time
                mins = elapsed / 60.0
                hrs = mins / 60.0
                log.info(f"Elapsed Time: {hrs:.3f} hours - {nodecnt} x {nodetype} - {OFS}")
            continue
        else:
            log.error(f"{aflow.name} failed - {OFS}")
            break


#####################################################################


if __name__ == '__main__':
    main()
