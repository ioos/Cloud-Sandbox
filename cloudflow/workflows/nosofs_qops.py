#!/usr/bin/env python3
print(f"file: {__file__} | name: {__name__} | package: {__package__}")

import collections
import os
import sys

if os.path.abspath('.') not in sys.path:
    sys.path.append(os.path.abspath('.'))

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

# Local dependencies
from utils import romsUtil as util
import flows

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

# Set these for specific use
curdir = os.path.dirname(os.path.abspath(__file__))

fcstconf = f'{curdir}/../cluster/configs/nosofs.config'
postconf = f'{curdir}/../cluster/configs/post.config'

# This is used for obtaining liveocean forcing data
# Users need to obtain credentials from UW
sshuser = 'username@boiler.ocean.washington.edu'


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
        if jobtype == 'forecast':
            fcstflow = flows.fcst_flow(fcstconf, jobfile, sshuser)
            flowdeq.appendleft(fcstflow)

        # Add the plot flow
        elif jobtype == 'plotting':
            postjobfile = jobfile
            plotflow = flows.plot_flow(postconf, jobfile)
            flowdeq.appendleft(plotflow)

        else:
            print(f"jobtype: {jobtype} is not supported")
            sys.exit()

    qlen = len(flowdeq)
    idx = 0

    while idx < qlen:
        aflow = flowdeq.pop()
        idx += 1
        state = aflow.run()
        print(f"DEBUG: state is: {state}")
        if state.is_successful():
            continue
        else:
            break


#####################################################################


if __name__ == '__main__':
    main()
