#!/usr/bin/env python3
""" Driver for running ADNOC forecasts """

import os
import sys
import re
from signal import signal, SIGINT, SIGTERM, SIGQUIT

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.workflows import tasks
from cloudflow.workflows import cluster_tasks as ctasks
from cloudflow.utils import modelUtil as util

# 3rd party dependencies
from prefect import Flow

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


curdir = os.path.dirname(os.path.abspath(__file__))

def handler(signal_received, frame):
    msg=f"{signal_received} detected. Exiting."
    print(msg)
    raise Exception(f"{signal_received} detected. Exiting gracefully.")


def fcst_flow(fcstconf, fcstjobfile ) -> Flow:
    """ Forecast workflow

    Parameters
    ----------
    fcstconf : str
        The cluster config file to use for this forecast.

    fcstjobfile : str
        The job config file to use for this forecast.

    Returns
    -------
    flow : prefect.Flow
    """

    with Flow('fcst workflow') as flow:
        #####################################################################
        # FORECAST
        #####################################################################

        # Create the cluster object
        cluster = ctasks.cluster_init(fcstconf)

        # Setup the job
        fcstjob = tasks.job_init(cluster, fcstjobfile)

        # Start the cluster
        cluster_start = ctasks.cluster_start(cluster)

        # Run the forecast
        fcst_run = tasks.forecast_run(cluster, fcstjob)

        # Terminate the cluster nodes
        cluster_stop = ctasks.cluster_terminate(cluster)

        flow.add_edge(cluster, fcstjob)
        flow.add_edge(fcstjob, cluster_start)
        flow.add_edge(cluster_start, fcst_run)
        flow.add_edge(fcst_run, cluster_stop)

        # If the fcst fails, then set the whole flow to fail
        flow.set_reference_tasks([fcst_run, cluster_stop])

    return flow

#######################################################################

def main():

    signals_to_handle = [SIGINT, SIGTERM, SIGQUIT]
    for sig in signals_to_handle:
        signal(sig, handler)

    lenargs = len(sys.argv) - 1

    if lenargs != 1:
        print(f"Usage: {sys.argv[0]} <jobfile>")
        sys.exit()

    fcstconf = f'{curdir}/../cluster/configs/adnoc.config'

    jobfile = os.path.abspath(sys.argv[1])
    jobdict = util.readConfig(jobfile)
    jobtype = jobdict["JOBTYPE"]

    if re.search("forecast", jobtype):
        # Add the forecast flow
        fcstflow = fcst_flow(fcstconf, jobfile)
    else:
        print(f"jobtype: {jobtype} is not supported")
        sys.exit()

    fcstflow.run()


if __name__ == '__main__':
    main()
