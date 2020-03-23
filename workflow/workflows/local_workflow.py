#!/usr/bin/env python3
# Local dependencies
import tasks
import job_tasks as jtasks
import cluster_tasks as ctasks

from dask.distributed import Client
# 3rd party dependencies
from prefect import Flow

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

# keep things cloud platform agnostic at this layer

# Set these for specific use

provider = 'Local'
# provider = 'AWS'

fcstconf = ''
fcstjobfile = ''
postconf = ''
postjobfile = ''

if provider == 'AWS':
    fcstconf = 'configs/liveocean.config'
    fcstjobfile = 'jobs/20191106.liveocean.job'
    postconf = 'configs/post.config'
    postjobfile = 'jobs/lo.plots.job'

elif provider == 'Local':
    fcstconf = 'configs/local.config'
    fcstjobfile = 'jobs/liveocean.job'
    postconf = 'configs/local.post'
    postjobfile = 'jobs/plots.local.job'

# This is used for obtaining liveocean forcing data
sshuser = 'username@boiler.ocean.washington.edu'

with Flow('plot only') as plotonly:
    # Start a machine
    postmach = ctasks.cluster_init(postconf, provider)
    pmStarted = ctasks.cluster_start(postmach)

    # Push the env, install required libs on post machine
    # TODO: install all of the 3rd party dependencies on AMI
    pushPy = ctasks.push_pyEnv(postmach, upstream_tasks=[pmStarted])

    # Start a dask scheduler on the new post machine
    daskclient: Client = ctasks.start_dask(postmach, upstream_tasks=[pmStarted])

    # Setup the post job
    postjob = tasks.job_init(postmach, postjobfile, upstream_tasks=[pmStarted])

    # Get list of files from fcstjob
    FILES = jtasks.ncfiles_from_Job(postjob)

    # Make plots
    plots = jtasks.daskmake_plots(daskclient, FILES, postjob)
    plots.set_upstream([daskclient])

    closedask = ctasks.dask_client_close(daskclient, upstream_tasks=[plots])
    pmTerminated = ctasks.cluster_terminate(postmach, upstream_tasks=[plots, closedask])

#######################################################################


with Flow('ofs workflow') as flow:
    #####################################################################
    # Pre-Process
    #####################################################################

    # Get forcing data
    # forcing = tasks.get_forcing(fcstjobfile,sshuser)

    #####################################################################
    # FORECAST
    #####################################################################

    # Create the cluster object
    cluster = ctasks.cluster_init(fcstconf, 'AWS')

    # Start the cluster
    fcStarted = ctasks.cluster_start(cluster)

    # Setup the job
    fcstjob = tasks.job_init(cluster, fcstjobfile)

    # Run the forecast
    fcstStatus = tasks.forecast_run(cluster, fcstjob)

    # Terminate the cluster nodes
    fcTerminated = ctasks.cluster_terminate(cluster)

    flow.add_edge(fcStarted, fcstjob)
    flow.add_edge(fcstjob, fcstStatus)
    flow.add_edge(fcstStatus, fcTerminated)

    #####################################################################
    # POST Processing
    #####################################################################
    # Spin up a new machine?
    # or launch a container?
    # or run concurrently on the forecast cluster?
    # or run on the local machine? concurrrently?

    # Start a machine
    postmach = ctasks.cluster_init(postconf, provider)
    pmStarted = ctasks.cluster_start(postmach, upstream_tasks=[fcstStatus])

    # Push the env, install required libs on post machine
    # TODO: install all of the 3rd party dependencies on AMI
    pushPy = ctasks.push_pyEnv(postmach, upstream_tasks=[pmStarted])

    # Start a dask scheduler on the new post machine
    daskclient = ctasks.start_dask(postmach, upstream_tasks=[pushPy])

    # Setup the post job
    postjob = tasks.job_init(postmach, postjobfile, upstream_tasks=[pmStarted])

    # Get list of files from fcstjob
    FILES = jtasks.ncfiles_from_Job(postjob, upstream_tasks=[fcstStatus])

    # Make plots
    plots = jtasks.daskmake_plots(daskclient, FILES, postjob)
    plots.set_upstream([daskclient])

    closedask = ctasks.dask_client_close(daskclient, upstream_tasks=[plots])
    pmTerminated = ctasks.cluster_terminate(postmach, upstream_tasks=[plots, closedask])


#####################################################################


def main():
    ''' Potential fix for Mac OS, fixed one thing but still wont run'''
    # mp.set_start_method('spawn')
    # mp.set_start_method('forkserver')

    # matplotlib Mac OS issues
    # flow.run()
    # testflow.run()
    # plotonly.run()


#####################################################################


if __name__ == '__main__':
    main()
