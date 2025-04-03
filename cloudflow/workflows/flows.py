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

provider = 'AWS'

# Our workflow log
log = logging.getLogger('workflow')
ch = logging.StreamHandler()
# log.setLevel(logging.DEBUG)
# ch.setLevel(logging.DEBUG)

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


def local_test_simple_fcst(fcstconf, fcstjobfile) -> Flow:

    with Flow('fcst workflow') as fcstflow:
        #####################################################################
        # FORECAST
        #####################################################################

        # Create the cluster object
        cluster = ctasks.cluster_init(fcstconf)

        # Setup the job
        fcstjob = tasks.job_init(cluster, fcstjobfile)

        # Get forcing data here

        # Run the forecast
        fcst_run = tasks.forecast_run(cluster, fcstjob)

        # If the fcst fails, then set the whole flow to fail
        fcstflow.set_reference_tasks([fcst_run])

    return fcstflow

######################################################################

def simple_fcst_flow(fcstconf, fcstjobfile) -> Flow:

    with Flow('fcst workflow') as fcstflow:
        #####################################################################
        # FORECAST
        #####################################################################

        # Create the cluster object
        cluster = ctasks.cluster_init(fcstconf)

        # Setup the job
        fcstjob = tasks.job_init(cluster, fcstjobfile)

        # Get forcing data here

        # Start the cluster
        cluster_start = ctasks.cluster_start(cluster, upstream_tasks=[fcstjob])

        # Run the forecast
        fcst_run = tasks.forecast_run(cluster, fcstjob, upstream_tasks=[cluster_start])

        # Terminate the cluster nodes
        cluster_stop = ctasks.cluster_terminate(cluster, upstream_tasks=[fcst_run])

        # If the fcst fails, then set the whole flow to fail
        fcstflow.set_reference_tasks([fcst_run])

    return fcstflow

######################################################################

def multi_hindcast_flow(hcstconf, hcstjobfile, sshuser) -> Flow: 

    """ Provides a Prefect Flow for a hindcast workflow.

    Parameters
    ----------
    hcstconf : str
        The JSON configuration file for the Cluster to create

    hcstjobfile : str
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
        hcstjob = tasks.job_init(cluster, hcstjobfile)

        # Get forcing data
        forcing = jtasks.get_forcing_multi(hcstjob, sshuser)

        # Start the cluster
        cluster_start = ctasks.cluster_start(cluster, upstream_tasks=[forcing, hcstjob])

        # Create the oceanin and run the forecasts
        # This will run in a loop to complete all forecasts 
        hcst_run = tasks.hindcast_run_multi(cluster, hcstjob, upstream_tasks=[cluster_start])

        # Terminate the cluster nodes
        cluster_stop = ctasks.cluster_terminate(cluster, upstream_tasks=[hcst_run])

        # Copy the results to /com (liveocean does not run in ptmp currently)
        #cp2com = jtasks.ptmp2com(hcstjob, upstream_tasks=[hcst_run])

        # Copy the results to S3 (optionally)
        #cp2s3 = jtasks.cp2s3(hcstjob, upstream_tasks=[hcst_run])
        #storage_service = tasks.storage_init(provider)
        #pngtocloud = tasks.save_to_cloud(plotjob, storage_service, ['*.png'], public=True)
        #pngtocloud.set_upstream(plots)

        # Copy the results to S3 (optionally. currently only saves LiveOcean)
        #storage_service = tasks.storage_init(provider)
        #cp2cloud = tasks.save_history(hcstjob, storage_service, ['*.nc'], public=True, upstream_tasks=[storage_service,cp2com])

        #pngtocloud.set_upstream(plots)

        # If the hcst fails, then set the whole flow to fail
        multiflow.set_reference_tasks([hcst_run])

    return multiflow

######################################################################


def fcst_flow(fcstconf, fcstjobfile, sshuser) -> Flow:
    """ Provides a Prefect Flow for a forecast workflow.

    Parameters
    ----------
    fcstconf : str
        The JSON configuration file for the Cluster to create

    fcstjobfile : str
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
        fcstjob = tasks.job_init(cluster, fcstjobfile)
       
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

def template_flow(conf, jobfile) -> Flow:
    """ Provides a Simple workflow execution in Cloud-Sandbox
        for any given model setup that a user wants to execute

    Parameters
    ----------
    conf : str
        The JSON configuration file for the Cluster to create

    jobfile : str
        The JSON configuration file for the model Job

    Returns
    -------
    flow : template.Flow
    """

    with Flow('template workflow') as template_flow:
        #####################################################################
        # FORECAST
        #####################################################################

        # Create the cluster object
        cluster = ctasks.cluster_init(conf)

        # Setup the job
        template_job = tasks.job_init(cluster, jobfile)

        # Start the cluster
        cluster_start = ctasks.cluster_start(cluster)

        # Run the model
        template_run = tasks.template_run(cluster, template_job, upstream_tasks=[cluster_start])

        # Terminate the cluster nodes
        cluster_stop = ctasks.cluster_terminate(cluster, upstream_tasks=[template_run])

        # If the model run fails, then set the whole flow to fail
        template_flow.set_reference_tasks([template_run])

    return template_flow


######################################################################

def reanalysis_flow(fcstconf, fcstjobfile) -> Flow:
    """ Provides a Prefect Flow for a reanalysis workflow. e.g. CORA ADCIRC

    Parameters
    ----------
    fcstconf : str
        The JSON configuration file for the Cluster to create

    fcstjobfile : str
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
        fcstjob = tasks.job_init(cluster, fcstjobfile)

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

def plot_flow(postconf, postjobfile) -> Flow:
    """ Provides a Prefect Flow for a plotting workflow. Also creates mpegs of sequential plots.
    Plots and mpegs are uploaded to the cloud.

    Parameters
    ----------
    postconf : str
        The JSON configuration file for the Cluster to create

    postjobfile : str
        The JSON configuration file for the plotting Job

    Returns
    -------
    plotflow : prefect.Flow
    """

    with Flow('plotting') as plotflow:
        #####################################################################
        # POST Processing
        #####################################################################

        # Start a machine
        postmach = ctasks.cluster_init(postconf)

        # Setup the post job
        plotjob = tasks.job_init(postmach, postjobfile)

        # Start the machine
        pmStarted = ctasks.cluster_start(postmach)

        # Push the env, install required libs on post machine
        # TODO: install all of the 3rd party dependencies on AMI
        pushPy = ctasks.push_pyEnv(postmach, upstream_tasks=[pmStarted])

        # Start a dask scheduler on the new post machine
        daskclient: Client = ctasks.start_dask(postmach, upstream_tasks=[pmStarted])

        # Get list of files from job specified directory
        FILES = jtasks.ncfiles_from_Job(plotjob)

        # Make plots
        plots = jtasks.daskmake_plots(daskclient, FILES, plotjob)
        plots.set_upstream([daskclient])

        storage_service = tasks.storage_init(provider)

        # Make movies
        mpegs = jtasks.daskmake_mpegs(daskclient, plotjob, upstream_tasks=[plots])
        mp4tocloud = tasks.save_to_cloud(plotjob, storage_service, ['*.mp4'], public=True)
        mp4tocloud.set_upstream(mpegs)

        closedask = ctasks.dask_client_close(daskclient, upstream_tasks=[mpegs])
        pmTerminated = ctasks.cluster_terminate(postmach, upstream_tasks=[mpegs, closedask])

        # Inject notebook
        notebook = 'cloudflow/inject/patrick/sandbot_current_fcst.py'
        injected = tasks.fetchpy_and_run(plotjob, storage_service, notebook)

        #######################################################################

    return plotflow


def diff_plot_flow(postconf, postjobfile, sshuser=None) -> Flow:
    """ Provides a Prefect Flow for a plotting workflow that plots the difference between the experimental or
    quasi-operational forecast and the official operational forecast. Also creates mpegs of sequential plots.
    Plots and mpegs are uploaded to the cloud.

    Parameters
    ----------
    postconf : str
        The JSON configuration file for the Cluster to create

    postjobfile : str
        The JSON configuration file for the plotting Job

    sshuser : str
        The optional user and host to use for retrieving data from a remote server.

    Returns
    -------
    diff_plotflow : prefect.Flow
    """

    with Flow('diff plotting') as diff_plotflow:
        #####################################################################
        # POST Processing
        #####################################################################

        # Read the post machine config
        postmach = ctasks.cluster_init(postconf)

        # Setup the post job
        plotjob = tasks.job_init(postmach, postjobfile)

        # Retrieve the baseline operational forecast data
        getbaseline = jtasks.get_baseline(plotjob, sshuser)

        # Start the machine
        pmStarted = ctasks.cluster_start(postmach, upstream_tasks=[getbaseline])

        # Push the env, install required libs on post machine
        # TODO: install all of the 3rd party dependencies on AMI
        #pushPy = ctasks.push_pyEnv(postmach, upstream_tasks=[pmStarted])

        # Start a dask scheduler on the new post machine
        #daskclient: Client = ctasks.start_dask(postmach, upstream_tasks=[pushPy])
        daskclient: Client = ctasks.start_dask(postmach)

        # Get list of files from job specified directory
        FILES = jtasks.ncfiles_from_Job(plotjob)
        BASELINE = jtasks.baseline_from_Job(plotjob, upstream_tasks=[getbaseline])

        # Make plots
        plots = jtasks.daskmake_diff_plots(daskclient, FILES, BASELINE, plotjob)
        plots.set_upstream([daskclient, getbaseline])

        # storage_service = tasks.storage_init(provider)
        #pngtocloud = tasks.save_to_cloud(plotjob, storage_service, ['*diff.png'], public=True)
        #pngtocloud.set_upstream(plots)

        # Make movies
        #mpegs = jtasks.daskmake_mpegs(daskclient, plotjob, diff=True, upstream_tasks=[plots])
        #mp4tocloud = tasks.save_to_cloud(plotjob, storage_service, ['*diff.mp4'], public=True)
        #mp4tocloud.set_upstream(mpegs)

        # closedask = ctasks.dask_client_close(daskclient, upstream_tasks=[mpegs])
        # pmTerminated = ctasks.cluster_terminate(postmach, upstream_tasks=[mpegs, closedask])

        closedask = ctasks.dask_client_close(daskclient, upstream_tasks=[plots])
        pmTerminated = ctasks.cluster_terminate(postmach, upstream_tasks=[plots, closedask])

        #######################################################################
        # This will add Kenny's script
        # https://ioos-cloud-sandbox.s3.amazonaws.com/cloudflow/inject/kenny/cloud_sandbot.py
        #notebook = 'cloudflow/inject/kenny/cloud_sandbot.py'
        #notebook = 'cloudflow/inject/patrick/sandbot_current_fcst.py'
        #injected = tasks.fetchpy_and_run(plotjob, storage_service, notebook)

    return diff_plotflow


def notebook_flow(postconf,jobfile) -> Flow:
    """ Provides a Prefect Flow for a running a python script in a Flow context. Originally designed for exported
    Jupyter Notebook .py scripts.

    Not fully tested. Designed for post jobs that require an on-demand compute node.

    Parameters
    ----------
    postconf : str
        The JSON configuration file for the Cluster to create

    jobfile : str
        The JSON configuration file for the post Job

    Returns
    -------
    nb_flow : prefect.Flow
    """

    with Flow('notebook flow') as nb_flow:
        #####################################################################
        # POST Processing
        #####################################################################

        postmach = ctasks.cluster_init(postconf)
        plotjob = tasks.job_init(postmach, jobfile)

        storage_service = tasks.storage_init(provider)
        # Optionally inject a user supplied python script
        #notebook = 'specify'
        #notebook = 'cloudflow/inject/kenny/cloud_sandbot.py'
        injected = tasks.fetchpy_and_run(plotjob, storage_service, notebook)

    return nb_flow


def notebook_test(pyfile) -> Flow:
    """ Provides a Prefect Flow for a running a python script in a Flow context. Originally designed for exported
    Jupyter Notebook .py scripts. Used to test user developed scripts before injection in quasi-operational workflows.

    Parameters
    ----------
    pyfile : str
        The python script to run.

    Returns
    -------
    nbtest_flow : prefect.Flow
    """
    with Flow('notebook test') as nbtest_flow:
        notebook_task = tasks.run_pynotebook(pyfile)
    return nbtest_flow


def test_flow(fcstconf, fcstjobfile) -> Flow:
    """ Provides a Prefect Flow for testing purposes.

    Parameters
    ----------
    fcstconf : str
        The JSON configuration file for the Cluster to create

    fcstjobfile : str
        The JSON configuration file for the Job

    Returns
    -------
    testflow : prefect.Flow
    """

    with Flow('test workflow') as testflow:

        # Create the cluster object
        cluster = ctasks.cluster_init(fcstconf)

        # Setup the job
        fcstjob = tasks.job_init(cluster, fcstjobfile)

        # Copy the results to S3 (optionally. currently only saves LiveOcean)
        storage_service = tasks.storage_init(provider)
        cp2cloud = tasks.save_history(fcstjob, storage_service, ['*.nc'], public=True, upstream_tasks=[storage_service, fcstjob])

    return testflow



def test_nbflow(pyfile: str):
    
    nbtest = notebook_test(pyfile)
    state = nbtest.run()

    if state.is_successful():
        return "PASSED"
    else:
        return "FAILED"



def debug_model(fcstconf, fcstjobfile, sshuser) -> Flow:

    with Flow('debug workflow') as debugflow:
        #####################################################################
        # FORECAST
        #####################################################################

        # Create the cluster object
        cluster = ctasks.cluster_init(fcstconf)

        # Setup the job
        fcstjob = tasks.job_init(cluster, fcstjobfile)

        # Note: These do not run in parallel as hoped

        # Get forcing data
        forcing = jtasks.get_forcing(fcstjob, sshuser)

        # scratch disk
        # TODO: /ptmp should come from the fcstjob?
        #scratch = tasks.create_scratch(provider,fcstconf,'/ptmp', upstream_tasks=[forcing])

        # Start the cluster
        cluster_start = ctasks.cluster_start(cluster, upstream_tasks=[forcing])

        # Mount the scratch disk
        #scratch_mount = tasks.mount_scratch(scratch, cluster, upstream_tasks=[cluster_start])

        # Run the forecast
        fcst_run = tasks.forecast_run(cluster, fcstjob, upstream_tasks=[cluster_start])

        # Terminate the cluster nodes
        #cluster_stop = ctasks.cluster_terminate(cluster, upstream_tasks=[fcst_run])

        # Copy the results to /com (liveocean)
        cp2com = jtasks.ptmp2com(fcstjob, upstream_tasks=[fcst_run])

        # Delete the scratch disk
        #scratch_delete = tasks.delete_scratch(scratch, upstream_tasks=[cp2com])

        # If the fcst fails, then set the whole flow to fail
        debugflow.set_reference_tasks([fcst_run])

    return debugflow



def inject_notebook() :
    ''' Convert the current notebook to python, test it, and upload it for the next forecast cycle.
    '''

    from cloudflow.utils import notebook as nbutils

    storage_provider = provider

    pyfile = nbutils.convert_notebook()

    # Run the converted notebook in a Prefect flow context
    nbtest_flow = notebook_test(pyfile)
    state = nbtest_flow.run()

    if state.is_successful():
        nbutils.inject(pyfile, storage_provider)
        return "PASSED"
    else:
        return "FAILED"

    print(result)

    if result == "PASSED":
        nbutils.inject(pyfile, storage_provider)


# Not being referenced anywhere here - unused
def handler(signal_received, frame):
    print('SIGINT or CTRL-C detected. Exiting gracefully')
    raise signals.FAIL()

if __name__ == '__main__':
    # signal(SIGINT, handler)
    pass

    # conf = f'./cluster/configs/debug.config'
    # jobfile = f'./job/jobs/ngofs.03z.fcst'
    # testflow = debug_model(conf, jobfile, 'none')
    # testflow.run()
