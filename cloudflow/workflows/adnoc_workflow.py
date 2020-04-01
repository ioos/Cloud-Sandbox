#!/usr/bin/env python3

# keep things cloud platform agnostic at this layer

import tasks as tasks
import cluster_tasks as ctasks

# 3rd party dependencies
from prefect import Flow

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

# Change the following for specific configurations and jobs
# provider = 'Local'
provider = 'AWS'

fcstconf = ""
fcstjobfile = ""

if provider == 'AWS':
    fcstconf = 'cluster/configs/adnoc.config'
    fcstjobfile = 'job/jobs/adnoc.job'
elif provider == 'Local':
    fcstconf = 'cluster/configs/local.config'
    fcstjobfile = 'job/jobs/adnoc.job'

with Flow('ofs workflow') as flow:
    #####################################################################
    # FORECAST
    #####################################################################

    # Create the cluster object
    cluster = ctasks.cluster_init(fcstconf, provider)

    # Start the cluster
    fcStarted = ctasks.cluster_start(cluster)

    # Setup the job
    fcstjob = tasks.job_init(cluster, fcstjobfile, 'roms')
    flow.add_edge(fcStarted, fcstjob)

    # Run the forecast
    fcstStatus = tasks.forecast_run(cluster, fcstjob)
    flow.add_edge(fcstjob, fcstStatus)

    # Terminate the cluster nodes
    fcTerminated = ctasks.cluster_terminate(cluster)
    flow.add_edge(fcstStatus, fcTerminated)


#######################################################################


def main():
    flow.run()


if __name__ == '__main__':
    main()
