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

#@flow(name="fcstflow")
#def fcst_flow(fcstconf, fcstjobfile, sshuser):

def simple_experiment_flow(cluster_conf, job_config) -> Flow:

    with Flow('model experiment workflow') as expflow:
        #####################################################################
        # Model Experiment Workflow
        #####################################################################

        # Create the cluster object
        cluster = ctasks.cluster_init(cluster_conf)

        # Setup the job
        expjob = tasks.job_init(cluster, job_config)

        # Start the cluster
        cluster_start = ctasks.cluster_start(cluster, upstream_tasks=[expjob])

        # Run the forecast
        exp_run = tasks.simple_run(cluster, expjob, upstream_tasks=[cluster_start])

        # Terminate the cluster nodes
        cluster_stop = ctasks.cluster_terminate(cluster, upstream_tasks=[exp_run])

        # If the exp fails, then set the whole flow to fail
        expflow.set_reference_tasks([exp_run])

    return expflow

######################################################################

def multi_hindcast_flow(hcstconf, jobfile, sshuser) -> Flow: 

    """ Provides a Prefect Flow for a hindcast workflow.

    Parameters
    ----------
    hcstconf : str
        The JSON configuration file for the Cluster to create

    jobfile : str
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
        cluster = ctasks.cluster_init(hcstconf)

        # Setup the job
        job = tasks.job_init(cluster, jobfile)

        # Get forcing data
        forcing = jtasks.get_forcing(job, sshuser)

        # scratch = tasks.create_scratch('FSx',jobfile,'/ptmp', upstream_tasks=[forcing])

        # Start the cluster
        cluster_start = ctasks.cluster_start(cluster, upstream_tasks=[forcing, job])

        # Mount the scratch disk
        #scratch_mount = tasks.mount_scratch(scratch, cluster, upstream_tasks=[cluster_start])

        # Create the oceanin and run the forecasts
        # This will run in a loop to complete all forecasts 
        hcst_run = tasks.hindcast_run_multi(cluster, job, upstream_tasks=[cluster_start])

        # Terminate the cluster nodes
        cluster_stop = ctasks.cluster_terminate(cluster, upstream_tasks=[hcst_run])

        # Copy the results to /com (liveocean does not run in ptmp currently)
        #cp2com = jtasks.ptmp2com(job, upstream_tasks=[hcst_run])

        # Copy the results to S3 (optionally)
        #cp2s3 = jtasks.cp2s3(job, upstream_tasks=[hcst_run])
        #storage_service = tasks.storage_init(provider)
        #pngtocloud = tasks.save_to_cloud(plotjob, storage_service, ['*.png'], public=True)
        #pngtocloud.set_upstream(plots)

        # Copy the results to S3 (optionally. currently only saves LiveOcean)
        #storage_service = tasks.storage_init(provider)
        #cp2cloud = tasks.save_history(job, storage_service, ['*.nc'], public=True, upstream_tasks=[storage_service,cp2com])

        #pngtocloud.set_upstream(plots)

        # If the hcst fails, then set the whole flow to fail
        multiflow.set_reference_tasks([hcst_run])

    return multiflow

######################################################################

@flow(name="fcstflow")
def fcst_flow(fcstconf, fcstjobfile, sshuser):
# def fcst_flow(fcstconf, fcstjobfile, sshuser) -> Flow:
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

#        # Copy the results to /com (liveocean does not run in ptmp currently)
#        cp2com = jtasks.ptmp2com(fcstjob, upstream_tasks=[fcst_run])
#
#        # Copy the results to S3 (optionally)
#        #cp2s3 = jtasks.cp2s3(fcstjob, upstream_tasks=[fcst_run])
#        #storage_service = tasks.storage_init(provider)
#        #pngtocloud = tasks.save_to_cloud(plotjob, storage_service, ['*.png'], public=True)
#        #pngtocloud.set_upstream(plots)
#
#        # Copy the results to S3 (optionally. currently only saves LiveOcean)
#        #storage_service = tasks.storage_init(provider)
#        #cp2cloud = tasks.save_history(fcstjob, storage_service, ['*.nc'], public=True, upstream_tasks=[storage_service,cp2com])
#
#        #pngtocloud.set_upstream(plots)
#
#        # If the fcst fails, then set the whole flow to fail
#        fcstflow.set_reference_tasks([fcst_run])
#
#    return fcstflow

######################################################################

def python_experiment_dask_flow(conf, jobfile) -> Flow:

    with Flow('python dask experiment workflow') as expflow:
        #####################################################################
        # Python Experiment Workflow
        #####################################################################

        # Start a machine
        cluster = ctasks.cluster_init(conf)

        # Setup the post job
        python_job = tasks.job_init(cluster, jobfile)

        # Start the machine
        cluster_online = ctasks.cluster_start(cluster)

        # Push the env, install required libs on post machine
        # TODO: install all of the 3rd party dependencies on AMI
        pushPy = ctasks.push_pyEnv(cluster, upstream_tasks=[cluster_online])

        # Start a dask scheduler on the new post machine
        daskclient: Client = ctasks.start_dask(cluster, upstream_tasks=[cluster_online])

        python_dask_experiment_run = tasks.python_dask_experiment_run(daskclient, python_job)
        python_dask_experiment_run.set_upstream([daskclient])
     
        # Teriminate the dask clinet session along with the cluster nodes
        closedask = ctasks.dask_client_close(daskclient,upstream_tasks=[python_dask_experiment_run])
        pmTerminated = ctasks.cluster_terminate(cluster,upstream_tasks=[python_dask_experiment_run,closedask])

    return expflow

######################################################################

def experiment_flow(conf, jobfile) -> Flow:
    """ Provides a Simple workflow execution in Cloud-Sandbox
        for any given model setup that a user wants to execute
        using the basic job configuration setup template

    Parameters
    ----------
    conf : str
        The JSON configuration file for the Cluster to create

    jobfile : str
        The JSON configuration file for the model Job

    Returns
    -------
    flow : experiment.Flow
    """

    with Flow('experiment workflow') as experiment_flow:
        #####################################################################
        # FORECAST
        #####################################################################

        # Create the cluster object
        cluster = ctasks.cluster_init(conf)

        # Setup the job
        experiment_job = tasks.job_init(cluster, jobfile)

        # Start the cluster
        cluster_start = ctasks.cluster_start(cluster)

        # Run the model
        experiment_run = tasks.experiment_run(cluster, experiment_job, upstream_tasks=[cluster_start])

        # Terminate the cluster nodes
        cluster_stop = ctasks.cluster_terminate(cluster, upstream_tasks=[experiment_run])

        # If the model run fails, then set the whole flow to fail
        experiment_flow.set_reference_tasks([experiment_run])

    return experiment_flow


######################################################################

if __name__ == '__main__':
    # signal(SIGINT, handler)
    pass

    # conf = f'./cluster/configs/debug.config'
    # jobfile = f'./job/jobs/ngofs.03z.fcst'
    # testflow = debug_model(conf, jobfile, 'none')
    # testflow.run()
