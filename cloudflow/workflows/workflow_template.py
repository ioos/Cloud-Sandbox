#!/usr/bin/env -S python3 -u
""" A driver to run a simplle hindcast workflow from provided job configuration files """

''' Usage:

    ./workflows/workflow_main.py hindcast-job

    Examples: ./workflows/workflow_main.py job/jobs/schism.hindcast

'''

import collections
import os
import sys
import re
from signal import signal, SIGINT, SIGTERM, SIGQUIT

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.utils import modelUtil as util
from cloudflow.workflows import flows

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

curdir = os.path.dirname(os.path.abspath(__file__))

######################################################################
# Set you AWS cloud configuration file here for your given
# model deployment on the cloud environment
######################################################################

template_conf = f'{curdir}/../cluster/configs/OWP/dflowfm.ioos'

######################################################################

def handler(signal_received, frame):
    msg=f"{signal_received} detected. Exiting."
    print(msg)
    raise Exception(f"{signal_received} detected. Exiting gracefully.")


## The template workflow driver script for any model run in Cloud-Sandbox ##
def main():

    signals_to_handle = [SIGINT, SIGTERM, SIGQUIT]
    for sig in signals_to_handle:
        signal(sig, handler)

    # Read in user defined job file
    jobfile = os.path.abspath(sys.argv[1])

    # Initialize collections item for flow object
    flowdeq = collections.deque()

    # Reads in job configuration file to inform
    # user of the job type they defined and are
    # running in this template workflow
    jobdict = util.readConfig(jobfile)
    jobtype = jobdict["JOBTYPE"]
    print('JOBTYPE: ', jobtype)


    simple_flow = flows.template_flow(template_conf, jobfile)
    flowdeq.appendleft(simple_flow)

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
