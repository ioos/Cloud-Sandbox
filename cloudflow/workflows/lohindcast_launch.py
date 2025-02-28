#!/usr/bin/env -S python3 -u
""" A driver to run workflows from provided job configuration files """

''' Usage:

'''

import collections
import os
import sys
import re
from signal import signal, SIGINT, SIGTERM, SIGQUIT


sys.stdout.reconfigure(line_buffering=False)

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.utils import modelUtil as util
from cloudflow.workflows import flows

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

curdir = os.path.dirname(os.path.abspath(__file__))

######################################################################
############### Set these for your specific deployment ###############
######################################################################

# NOS or IOOS(RPS)
fcstconf = f'{curdir}/../cluster/configs/NOS/nos.liveocean.cfg'
#fcstconf = f'{curdir}/../cluster/configs/RPS/ioos.liveocean.cfg'
#fcstconf = f'{curdir}/../cluster/configs/RPS/test.liveocean.cfg'

# This is used for obtaining liveocean forcing data
# LiveOcean users need to obtain credentials from UW

# NOTE: Your ssh public key will need to be added to apogee .ssh/authorized_keys file for passwordless scp.
sshuser = 'username@apogee.ocean.washington.edu'

######################################################################

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
        print('JOBTYPE: ', jobtype)

        if re.search("hindcast", jobtype):
           # Add the hindcast flow
            hindcastflow = flows.multi_hindcast_flow(fcstconf, jobfile, sshuser)
            flowdeq.appendleft(hindcastflow)

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
