#!/usr/bin/env -S python3 -u
""" A driver to run workflows from provided job configuration files """

''' Usage:

    ./workflows/workflow_main.py fcst-job [post-job]

    Examples: ./workflows/workflow_main.py job/jobs/cbofs.00z.fcst 

'''

import collections
import os
import sys
import re
from signal import signal, SIGINT

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.utils import romsUtil as util
from cloudflow.workflows import flows

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

curdir = os.path.dirname(os.path.abspath(__file__))

######################################################################
############### Set these for your specific deployment ###############
######################################################################

#fcstconf = f'{curdir}/../cluster/configs/NOS/cora.hsofs.cfg'
#fcstconf = f'{curdir}/../cluster/configs/RPS/ioos.cora.cfg'
#fcstconf = f'{curdir}/../cluster/configs/RPS/test.cora.cfg'
#fcstconf = f'{curdir}/../cluster/configs/NOS/nos.cora.cfg'
#postconf = f'{curdir}/../cluster/configs/local.config'

# This is used for obtaining liveocean forcing data
# LiveOcean users need to obtain credentials from UW
sshuser = 'username@ocean.washington.edu'

######################################################################

def handler(signal_received, frame):
    print('SIGINT or CTRL-C detected. Exiting gracefully')
    raise signal.FAIL()

def main():

    signal(SIGINT, handler)

    lenargs = len(sys.argv) - 1
    joblist = []

    # TODO: require a cluster config file when starting a job, provide job-specific node Name tag
    # if lenargs < 2:
    #     print(f"Usage: {os.path.basename(__file__)} cluster_config job [job2 job3 ...]")
    #     print(f"    example: {os.path.basename(__file__)} cluster/configs/NOS/nos.cora.cfg myjobs/cora.reanalysis")
    #     sys.exit(1)
    # idx = 2

    if lenargs < 1:
        print(f"Usage: {os.path.basename(__file__)} job_config [job2_config job3_config ...]")
        print(f"    example: {os.path.basename(__file__)} myjobs/cora.reanalysis")
        sys.exit(1)

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

        elif re.search("hindcast", jobtype):
           # Add the hindcast flow
            hindcastflow = flows.multi_hindcast_flow(fcstconf, jobfile, sshuser)
            flowdeq.appendleft(hindcastflow)

        elif jobtype == "adcircreanalysis":
            raflow = flows.reanalysis_flow(fcstconf, jobfile)
            flowdeq.appendleft(raflow)

        elif jobtype == "plotting":
            # Add the plot flow
            plotflow = flows.plot_flow(postconf, jobfile)
            flowdeq.appendleft(plotflow)

        elif jobtype == "plotting_diff":
            # Add the diff plot flow
            diffplotflow = flows.diff_plot_flow(postconf, jobfile)
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

        # Stop if the flow failed
        state = aflow.run()
        if state.is_successful():
            continue
        else:
            break


#####################################################################


if __name__ == '__main__':
    main()
