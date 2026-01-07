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
from prefect import Flow
from prefect.engine import signals


if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))
if os.path.abspath('.') not in sys.path:
    sys.path.append(os.path.abspath('.'))

from cloudflow.workflows import tasks
from cloudflow.workflows import cluster_tasks as ctasks
from cloudflow.workflows import job_tasks as jtasks

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

#SCRATCH_TYPE = 'FSx'
SCRATCH_TYPE = 'None'

def sig_handler(signal_received, frame):
    msg=f"{signal_received} detected."
    print(msg)
    raise signals.FAIL('FAILED')

def block_ctlc(signal_received, frame):
    msg=f"{signal_received} - Ctl-C is disabled"
    print(msg)    

# TODO: imrove on this
    # This might be better, or simply exit
    #signal.raise_signal(signum)
    # Sends a signal to the calling process. Returns nothing.

#signals_to_handle = [SIGINT, SIGTERM, SIGQUIT]
signals_to_handle = [SIGTERM, SIGQUIT]
for sig in signals_to_handle:
    signal(sig, sig_handler)

# Block all Ctl-C
signal(SIGINT, block_ctlc)

provider = 'AWS'

# Our workflow log
log = logging.getLogger('workflow')
ch = logging.StreamHandler()
log.setLevel(logging.DEBUG)
ch.setLevel(logging.DEBUG)

formatter = logging.Formatter(' %(asctime)s  %(levelname)s - %(module)s.%(funcName)s | %(message)s')
formatter.converter = time.localtime
ch.setFormatter(formatter)
log.addHandler(ch)

# Fix the prefect logger to output local time instead of gmtime
# Prefect uses this: formatter.converter = time.gmtime
prelog = prefect.utilities.logging.get_logger()
#prelog.handler.formatter.converter = time.localtime

# Use the same handler for all of them
for handler in prelog.handlers:
    pformatter = logging.Formatter('[%(asctime)s] %(levelname)s - %(module)s.%(funcName)s | %(message)s')
    pformatter.converter = time.localtime
    handler.setFormatter(pformatter)


def multi_hindcast_flow(cluster_config, job_config, sshuser) -> Flow: 

    """ Provides a Prefect Flow for a hindcast workflow.

    Parameters
    ----------
    cluster_config : str
        The JSON configuration file for the Cluster to create

    job_config : str
        The JSON configuration file for the hindcast Job

    sshuser : str
        The user and host to use for retrieving data from a remote server.

    Returns
    -------
    hindcastflow : prefect.Flow
    """

    with Flow('multi hindcast workflow') as multiflow:
        #####################################################################
        # HINDCAST
        #####################################################################

        # Create the cluster object
        cluster = ctasks.cluster_init(cluster_config)

        # Setup the job
        job = tasks.job_init(cluster, job_config)

        # Get forcing data
        forcing = jtasks.get_forcing_multi(job, sshuser)

        # Create scratch disk
        # scratch = tasks.create_scratch('FSx', cluster, job, upstream_tasks=[forcing])

        # Copy the run to /ptmp
        # cp2ptmp = jtasks.com2ptmp(job, upstream_tasks=[scratch])

        # Start the cluster
        #cluster_start = ctasks.cluster_start(cluster, upstream_tasks=[forcing, cp2ptmp])
        cluster_start = ctasks.cluster_start(cluster, upstream_tasks=[forcing])

        # Mount the scratch disk on the cluster nodes
        # scratch_remote_mount = tasks.scratch_remote_mount(scratch, cluster, job, upstream_tasks=[cluster_start])

        # Create the oceanin and run the forecasts
        # This will run in a loop to complete all forecasts 
        #hcst_run = tasks.hindcast_run_multi(cluster, job, upstream_tasks=[cluster_start, scratch_remote_mount])
        hcst_run = tasks.hindcast_run_multi(cluster, job, upstream_tasks=[cluster_start])

        # Terminate the cluster nodes
        cluster_stop = ctasks.cluster_terminate(cluster, upstream_tasks=[hcst_run])

        # move data from scratch
        # Copy the results to /com
        # cp2com = jtasks.ptmp2com(job, upstream_tasks=[hcst_run])

        # Delete the scratch disk
        #scratch_delete = tasks.delete_scratch(scratch, upstream_tasks=[cp2com])

        # If the hcst fails, then set the whole flow to fail
        multiflow.set_reference_tasks([hcst_run])

    return multiflow

######################################################################


def fcst_flow(fcstconf, fcstjob_config, sshuser) -> Flow:
    """ Provides a Prefect Flow for a forecast workflow.

    Parameters
    ----------
    fcstconf : str
        The JSON configuration file for the Cluster to create

    fcstjob_config : str
        The JSON configuration file for the forecast Job

    sshuser : str
        The user and host to use for retrieving data from a remote server.

    Returns
    -------
    fcstflow : prefect.Flow
    """

    with Flow('fcst workflow') as fcstflow:
        #####################################################################
        # FORECAST
        #####################################################################

        # Create the cluster object
        cluster = ctasks.cluster_init(fcstconf)

        # Setup the job
        fcstjob = tasks.job_init(cluster, fcstjob_config)
       
        # Get forcing data
        forcing = jtasks.get_forcing(fcstjob, sshuser)

        # Start the cluster
        cluster_start = ctasks.cluster_start(cluster, upstream_tasks=[forcing])

        # Run the forecast
        fcst_run = tasks.forecast_run(cluster, fcstjob, upstream_tasks=[cluster_start])
        
        # Terminate the cluster nodes
        cluster_stop = ctasks.cluster_terminate(cluster, upstream_tasks=[fcst_run])

        # Copy the results to /com (liveocean does not run in ptmp currently)
        cp2com = jtasks.ptmp2com(fcstjob, upstream_tasks=[fcst_run])

        # Copy the results to S3 (optionally)
        #cp2s3 = jtasks.cp2s3(fcstjob, upstream_tasks=[fcst_run])
        #storage_service = tasks.storage_init(provider)
        #pngtocloud = tasks.save_to_cloud(plotjob, storage_service, ['*.png'], public=True)
        #pngtocloud.set_upstream(plots)

        # Copy the results to S3 (optionally. currently only saves LiveOcean)
        #storage_service = tasks.storage_init(provider)
        #cp2cloud = tasks.save_history(fcstjob, storage_service, ['*.nc'], public=True, upstream_tasks=[storage_service,cp2com])

        #pngtocloud.set_upstream(plots)

        # If the fcst fails, then set the whole flow to fail
        fcstflow.set_reference_tasks([fcst_run])

    return fcstflow

######################################################################

def reanalysis_flow(fcstconf, fcstjob_config) -> Flow:
    """ Provides a Prefect Flow for a reanalysis workflow. e.g. CORA ADCIRC

    Parameters
    ----------
    fcstconf : str
        The JSON configuration file for the Cluster to create

    fcstjob_config : str
        The JSON configuration file for the forecast Job

    sshuser : str
        The user and host to use for retrieving data from a remote server.

    Returns
    -------
    fcstflow : prefect.Flow
    """

    with Flow('reanalysis workflow') as raflow:
        #####################################################################
        # FORECAST
        #####################################################################

        # Create the cluster object
        cluster = ctasks.cluster_init(fcstconf)

        # Setup the job
        fcstjob = tasks.job_init(cluster, fcstjob_config)

        # Get forcing data
        # Forcing should be retrieved external to this flow before running
        # forcing = jtasks.get_forcing(fcstjob, sshuser)

        # Start the cluster
        #cluster_start = ctasks.cluster_start(cluster, upstream_tasks=[forcing])
        cluster_start = ctasks.cluster_start(cluster)

        # Run the forecast
        fcst_run = tasks.cora_reanalysis_run(cluster, fcstjob, upstream_tasks=[cluster_start])

        # Terminate the cluster nodes
        cluster_stop = ctasks.cluster_terminate(cluster, upstream_tasks=[fcst_run])

        # Copy the results to /com (liveocean does not run in ptmp currently)
        #cp2com = jtasks.ptmp2com(fcstjob, upstream_tasks=[fcst_run])

        # Copy the results to S3 (optionally)
        #cp2s3 = jtasks.cp2s3(fcstjob, upstream_tasks=[fcst_run])
        #storage_service = tasks.storage_init(provider)
        #pngtocloud = tasks.save_to_cloud(plotjob, storage_service, ['*.png'], public=True)
        #pngtocloud.set_upstream(plots)

        # Copy the results to S3 (optionally. currently only saves LiveOcean)
        #storage_service = tasks.storage_init(provider)
        #cp2cloud = tasks.save_history(fcstjob, storage_service, ['*.nc'], public=True, upstream_tasks=[storage_service,cp2com])

        #pngtocloud.set_upstream(plots)

        # If the fcst fails, then set the whole flow to fail
        raflow.set_reference_tasks([fcst_run])

    return raflow

######################################################################


# Not being referenced anywhere here - unused
#def handler(signal_received, frame):
#    print('SIGINT or CTRL-C detected. Exiting gracefully')
#    raise signals.FAIL()

if __name__ == '__main__':

    # pass

    cluster_config = f'./fsx.test'
    job_config = f'./job/jobs/test.schism.secofs'
    flow = multi_hindcast_flow(cluster_config, job_config, None)
    flow.run()

    # cluster_config = f'./cluster/configs/debug.config'
    # job_config = f'./job/jobs/ngofs.03z.fcst'
    # flow = multi_hindcast_flow
    # flow.run()


