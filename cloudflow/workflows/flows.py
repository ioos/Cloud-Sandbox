#!/usr/bin/python3 -u
""" Collection of functions that provide pre-defined Prefect Flow contexts for use in the cloud """

import os
import sys
import time

# TODO: add additional signal handlers for more robust cleanup of failed runs
from signal import signal, SIGINT, SIGTERM, SIGQUIT

import logging
from distributed import Client
import prefect
from prefect import flow

# Relook into prefect signal handling, i just had a case of Ctl-C causing a zombie node

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))
if os.path.abspath('.') not in sys.path:
    sys.path.append(os.path.abspath('.'))

from cloudflow.workflows import tasks
from cloudflow.workflows import cluster_tasks as ctasks
from cloudflow.workflows import job_tasks as jtasks

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

provider = 'AWS'

# Our workflow log
log = logging.getLogger('workflow')
ch = logging.StreamHandler()

log.setLevel(logging.INFO)
ch.setLevel(logging.INFO)
# log.setLevel(logging.DEBUG)
# ch.setLevel(logging.DEBUG)

formatter = logging.Formatter(' %(asctime)s  %(levelname)s - %(module)s.%(funcName)s | %(message)s')
formatter.converter = time.localtime
ch.setFormatter(formatter)
log.addHandler(ch)

# Fix the prefect logger to output local time instead of gmtime
# Prefect uses this: formatter.converter = time.gmtime
prelog = prefect.logging.loggers.get_logger()
#prelog.handler.formatter.converter = time.localtime
# Use the same handler for all of them
for handler in prelog.handlers:
    pformatter = logging.Formatter('[%(asctime)s] %(levelname)s - %(module)s.%(funcName)s | %(message)s')
    pformatter.converter = time.localtime
    handler.setFormatter(pformatter)


######################################################################

@flow(name="fcstflow")
def fcst_flow(fcstconf, fcstjobfile, sshuser):
    """ Provides a Prefect Flow for a forecast workflow.

    Parameters
    ----------
    fcstconf : str
        The JSON configuration file for the Cluster to create

    fcstjobfile : str
        The JSON configuration file for the forecast Job

    sshuser : str
        The user and host to use for retrieving data from a remote server.
    """

    #####################################################################
    # FORECAST
    #####################################################################

    # Create the cluster object
    cluster = ctasks.cluster_init(fcstconf)

    # Setup the job
    fcstjob = tasks.job_init(cluster, fcstjobfile)
   
    # Get forcing data
    jtasks.get_forcing(fcstjob, sshuser)

    # Start the cluster
    ctasks.cluster_start(cluster)

    # Run the forecast
    try:
      tasks.forecast_run(cluster, fcstjob)
    except Exception as e:
      log.exception('forecast_run failed')

    # Terminate the cluster nodes
    ctasks.cluster_terminate(cluster)


######################################################################

if __name__ == '__main__':
    # signal(SIGINT, handler)
    pass

    # conf = f'./cluster/configs/debug.config'
    # jobfile = f'./job/jobs/ngofs.03z.fcst'
    # testflow = debug_model(conf, jobfile, 'none')
    # testflow.run()
