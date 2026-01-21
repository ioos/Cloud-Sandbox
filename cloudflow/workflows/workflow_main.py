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
from signal import signal, SIGINT, SIGTERM, SIGQUIT

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.utils import modelUtil as util
from cloudflow.workflows import flows

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

curdir = os.path.dirname(os.path.abspath(__file__))

# TODO: block ctl-c signal

######################################################################
############### Set these for your specific deployment ###############
######################################################################

# This is used for obtaining liveocean forcing data
# LiveOcean users need to obtain credentials from UW
sshuser = os.environ.get("LO_SSHUSER", "username@ocean.washington.edu")

######################################################################

def handler(signal_received, frame):
    msg=f"{signal_received} detected. Exiting."
    print(msg)
    raise Exception(f"{signal_received} detected. Exiting gracefully.")

    # TODO: improve on this
    # This might be better, or simply exit
    #signal.raise_signal(signum)
    # Sends a signal to the calling process. Returns nothing.


def main():

    signals_to_handle = [SIGINT, SIGTERM, SIGQUIT]
    for sig in signals_to_handle:
        signal(sig, handler)

    lenargs = len(sys.argv) - 1

    # TODO: require a cluster config file when starting a job, provide job-specific node Name tag

    # PT 12/29/2025 Removed unused option of multiple jobs as parameters
    #               users can easily script that if desired

    #print(f"lenargs: {lenargs}")
    if lenargs !=  2:
        print(f"Usage: {os.path.basename(__file__)} cluster_config job_config")
        print(f"    example: {os.path.basename(__file__)} cluster/configs/NOS/nos.cora.cfg myjobs/cora.reanalysis")
        sys.exit(1)

    conf = os.path.abspath(sys.argv[1])
    jobfile = os.path.abspath(sys.argv[2])

    jobdict = util.readConfig(jobfile)
    jobtype = jobdict["JOBTYPE"]
    print(f"jobtype: {jobtype}")

    if re.search("forecast", jobtype):
        flows.fcst_flow(conf, jobfile, sshuser)

    elif re.search("hindcast", jobtype):
        flows.multi_hindcast_flow(conf, jobfile, sshuser)

    elif jobtype == "adcircreanalysis":
        flows.reanalysis_flow(conf, jobfile)

    elif jobtype == "plotting":
        flows.plot_flow(postconf, jobfile)

    elif jobtype == "plotting_diff":
        flows.diff_plot_flow(postconf, jobfile)

    elif re.search("experiment", jobtype):
        if re.search("dask",jobdict["APP"]):
            flows.python_experiment_dask_flow(conf, jobfile)
        else:
            flows.experiment_flow(conf, jobfile)
    else:
        print(f"jobtype: {jobtype} is not supported")
        sys.exit()


#####################################################################


if __name__ == '__main__':
    main()
