#!/usr/bin/env python3
import collections
import os
import sys
import re

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

import utils.romsUtil as util
import flows

__copyright__ = "Copyright © 2020 RPS Group. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

curdir = os.path.dirname(os.path.abspath(__file__))

# provider = 'Local'
# provider = 'AWS'
fcstconf = f'{curdir}/../configs/ioos.config'
postconf = f'{curdir}/../configs/post.config'

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

        if re.search("forecast", jobtype):
        # Add the forecast flow
            fcstflow = flows.fcst_flow(fcstconf, jobfile, sshuser)
            flowdeq.appendleft(fcstflow)

        # Add the plot flow
        elif re.search("plotting", jobtype):
            postjobfile = jobfile
            plotflow = flows.plot_flow(postconf, jobfile)
            flowdeq.appendleft(plotflow)

        else:
            print(f"jobtype: {jobtype} is not supported")
            sys.exit()

    qlen = len(flowdeq)
    idx = 0


    # Run all of the flows in the queue
    while idx < qlen:
        aflow = flowdeq.pop()
        idx += 1

        # Stop if the flow failed
        state = aflow.run()
        if state.is_successful():
            continue
        else:
            break


#####################################################################


if __name__ == '__main__':
    main()
