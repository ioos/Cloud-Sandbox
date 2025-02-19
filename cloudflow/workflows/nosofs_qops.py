#!/usr/bin/env python3
""" Driver for quasi-operational workflows """
import collections
import logging
import os
import re
import sys
import time
import math
from pathlib import Path
from signal import signal, SIGINT, SIGTERM, SIGQUIT

if os.path.abspath('.') not in sys.path:
    sys.path.append(os.path.abspath('.'))

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

# Local dependencies
from cloudflow.utils import modelUtil as util
from cloudflow.workflows import flows

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


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
# Only add one handler.
if not log.hasHandlers():
    log.addHandler(ch)


def handler(signal_received, frame):
    msg=f"{signal_received} detected. Exiting."
    print(msg)
    raise Exception(f"{signal_received} detected. Exiting gracefully.")


def main():

    signals_to_handle = [SIGINT, SIGTERM, SIGQUIT]
    for sig in signals_to_handle:
        signal(sig, handler)

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
        OFS = jobdict["OFS"]

        print('JOBTYPE: ', jobtype)

        # Add the forecast flow
        if re.search("forecast", jobtype):
            fcstdict = util.readConfig(fcstconf)
            nodetype = fcstdict["nodeType"]
            nodecnt = fcstdict["nodeCount"]

            if 'NTIMES' in jobdict:
                ntimes = jobdict['NTIMES']
            else:
                ntimes = None

            if 'NHOURS' in jobdict:
                nhours = jobdict['NHOURS']
            else:
                nhours = None
            
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
                mins = math.ceil(elapsed / 60.0)
                hrs = mins / 60.0
                if ntimes:
                    log.info(f"Elapsed Time: {mins:.0f} minutes, ntimes:{ntimes}, {nodecnt}x {nodetype} - {OFS}")
                else:
                    log.info(f"Elapsed Time: {mins:.0f} minutes, nhours:{nhours}, {nodecnt}x {nodetype} - {OFS}")
            continue
        else:
            log.error(f"{aflow.name} failed - {OFS}")
            break


#####################################################################


if __name__ == '__main__':
    main()
