#!/usr/bin/python3 -u
""" Collection of functions that provide pre-defined Prefect Flow contexts for use in the cloud """

import os
import sys
import time
import logging

from distributed import Client
import prefect
from prefect import flow
from prefect.context import get_run_context

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))
if os.path.abspath('.') not in sys.path:
    sys.path.append(os.path.abspath('.'))

from cloudflow.workflows import tasks
from cloudflow.workflows import cluster_tasks as ctasks
from cloudflow.workflows import job_tasks as jtasks

__copyright__ = "Copyright © 2025 Tetra Tech, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

provider = 'AWS'

# Our workflow log
log = logging.getLogger('workflow')
ch = logging.StreamHandler()

log.setLevel(logging.INFO)
ch.setLevel(logging.INFO)

#log.setLevel(logging.DEBUG)
#ch.setLevel(logging.DEBUG)

formatter = logging.Formatter(' %(asctime)s  %(levelname)s - %(module)s.%(funcName)s | %(message)s')
formatter.converter = time.localtime
ch.setFormatter(formatter)
log.addHandler(ch)

# Fix the prefect logger to output local time instead of gmtime
# Prefect uses this: formatter.converter = time.gmtime
#prelog.handler.formatter.converter = time.localtime
prelog = prefect.logging.loggers.get_logger()

# Use the same handler for all of them
for handler in prelog.handlers:
    pformatter = logging.Formatter('[%(asctime)s] %(levelname)s - %(module)s.%(funcName)s | %(message)s')
    pformatter.converter = time.localtime
    handler.setFormatter(pformatter)



######################################################################
@flow
def simple_experiment_flow(conf, jobfile):
    """
    """

    #####################################################################
    # Model Experiment Workflow
    #####################################################################

    # Create the cluster object
    cluster = ctasks.cluster_init(conf)

    # Setup the job
    expjob = tasks.job_init(cluster, jobfile)

    # Start the cluster
    try:
        ctasks.cluster_start(cluster)
    except Exception as e:
        log.exception('cluster_start failed')
        raise

    # Run the forecast
    try:
        tasks.simple_run(cluster, expjob)
    except Exception as e:
        log.exception('simple_run failed')

    # Terminate the cluster nodes
    ctasks.cluster_terminate(cluster)

    


######################################################################

@flow
def multi_hindcast_flow(conf, jobfile, sshuser=None):

    """ Provides a Prefect Flow for a hindcast workflow.
  
        This flow is for running consectutive daily hindcasts/forecasts using 
        the same on-demand cluster.

    Parameters
    ----------
    conf : str
        The JSON configuration file for the Cluster to create

    jobfile : str
        The JSON configuration file for the hindcast Job

    sshuser : str
        The user and host to use for retrieving data from a remote server.

    """

    #####################################################################
    # HINDCAST
    #####################################################################

    # Create the cluster object
    cluster = ctasks.cluster_init(conf)

    # Setup the job
    job = tasks.job_init(cluster, jobfile)

    # Get forcing data
    jtasks.get_forcing(job, sshuser)

    #tasks.create_scratch('FSx',jobfile,'/ptmp')

    # Start the cluster
    try:
        ctasks.cluster_start(cluster)
    except Exception as e:
        log.exception('cluster_start failed')
        raise

    # Mount the scratch disk
    # tasks.mount_scratch(scratch, cluster)

    # Create the oceanin and run the forecasts
    # This will run in a loop to complete all forecasts 
    try:
        tasks.hindcast_run_multi(cluster, job)
    except Exception as e:
        log.exception('forecast_run failed')

    # Terminate the cluster nodes
    ctasks.cluster_terminate(cluster)

    # Copy the results to /com (liveocean does not run in ptmp currently)
    #jtasks.ptmp2com(job)

    # Copy the results to S3 (optionally)
    #jtasks.cp2s3(job)
    #storage_service = tasks.storage_init(provider)
    #pngtocloud = tasks.save_to_cloud(plotjob, storage_service, ['*.png'], public=True)

    # Copy the results to S3 (optionally. currently only saves LiveOcean)
    #storage_service = tasks.storage_init(provider)
    #tasks.save_history(job, storage_service, ['*.nc'], public=True)



######################################################################

@flow
def fcst_flow(fcstconf, fcstjobfile, sshuser=None):
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

    # Retrieve runtime context
    context = get_run_context()
    
    # Get flow run details
    flow_run_id = context.flow_run.id
    flow_run_name = context.flow_run.name
    print(f"Running flow: {flow_run_name} (ID: {flow_run_id})")

    # Create the cluster object
    cluster = ctasks.cluster_init(fcstconf)

    # Setup the job
    fcstjob = tasks.job_init(cluster, fcstjobfile)
   
    # Get forcing data
    jtasks.get_forcing(fcstjob, sshuser)

    # Start the cluster
    try:
      ctasks.cluster_start(cluster)
    except Exception as e:
      log.exception('cluster_start failed')
      raise

    # Run the forecast
    try:
      tasks.forecast_run(cluster, fcstjob)
    except Exception as e:
      log.exception('forecast_run failed')

    # Terminate the cluster nodes
    ctasks.cluster_terminate(cluster)




######################################################################
@flow
def python_experiment_dask_flow(conf, jobfile):
    """
    """

    #####################################################################
    # Python Experiment Workflow
    #####################################################################

    # Start a machine
    cluster = ctasks.cluster_init(conf)

    # Setup the post job
    python_job = tasks.job_init(cluster, jobfile)

    # Start the machine
    try:
        ctasks.cluster_start(cluster)
    except Exception as e:
        log.exception('cluster_start failed')
        raise

    try:
        # Start a dask scheduler on the new post machine
        # Might get a not serializable error message from prefect
        # distributed.Client might not be serializable, Prefect 3 needs to pickle and store the data in the cache
        cluster, dask_address = ctasks.start_dask(cluster)

        # Run the python dask experiment
        tasks.python_dask_experiment_run(dask_address, python_job)
    except Exception as e:
        log.exception('Python_dask_experiment_run failed')


    # Teriminate the dask scheduler and dask ssh commands linked
    # to the client and workers. Ensure an exception can be
    # caught in case the start_dask workflow never sucessfully
    # completed and we did not start up any scheduler and workers
    try:
        cluster = ctasks.dask_client_close(cluster)
    except Exception as e:
        log.exception('dask_client_close failed, likely due to nonexistent processes')

    # Terminate the AWS resources allocated for dask job
    ctasks.cluster_terminate(cluster)



######################################################################
@flow
def experiment_flow(conf, jobfile):
    """ Provides a Simple workflow execution in Cloud-Sandbox
        for any given model setup that a user wants to execute
        using the basic job configuration setup template

    Parameters
    ----------
    conf : str
        The JSON configuration file for the Cluster to create

    jobfile : str
        The JSON configuration file for the model Job

    """

    #####################################################################
    # FORECAST
    #####################################################################

    # Create the cluster object
    cluster = ctasks.cluster_init(conf)

    # Setup the job
    experiment_job = tasks.job_init(cluster, jobfile)

    # Start the cluster
    try:
        ctasks.cluster_start(cluster)
    except Exception as e:
        log.exception('cluster_start failed')
        raise

    # Run the model
    try:
        tasks.experiment_run(cluster, experiment_job)
    except Exception as e:
        log.exception('experiment_run failed')

    # Terminate the cluster nodes
    ctasks.cluster_terminate(cluster)




######################################################################

if __name__ == '__main__':
    pass

    # conf = f'./cluster/configs/debug.config'
    # jobfile = f'./job/jobs/ngofs.03z.fcst'
    # debug_model(conf, jobfile, 'none')
