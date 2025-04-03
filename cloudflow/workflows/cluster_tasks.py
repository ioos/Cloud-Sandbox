"""
Various cluster related functions wrapped as Prefect Tasks
"""

# Python dependencies
import glob
import logging
import os
import sys
import time
import traceback
import subprocess
import pprint
from distributed import Client
from prefect import task
from prefect.engine import signals
from prefect.triggers import all_finished

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.cluster.Cluster import Cluster
from cloudflow.cluster.ClusterFactory import ClusterFactory

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


curdir = os.path.dirname(os.path.abspath(__file__))

pp = pprint.PrettyPrinter()

log = logging.getLogger('workflow')

#######################################################################


# cluster
@task
def cluster_init(config) -> Cluster:
    """ Create a new Cluster object using the ClusterFactory

    Parameters
    ----------
    config : string

    Returns
    -------
    newcluster : Cluster
        Object returned will be a sub-class of Cluster
    """
    factory = ClusterFactory()
    newcluster = factory.cluster(config)

    return newcluster

#######################################################################


# cluster
@task
def cluster_start(cluster):
    """ Start the cluster

    Parameters
    ----------
    cluster : Cluster

    """
    log.info('Starting ' + str(cluster.nodeCount) + ' instances ...')
    log.info('Waiting for nodes to start ...')
    try:
        cluster.start()
    except Exception as e:
        log.exception('In driver: Exception while creating nodes :' + str(e))
        raise signals.FAIL()
    return


#######################################################################


# cluster
@task(trigger=all_finished)
def cluster_terminate(cluster):
    """ Terminate the cluster

    Parameters
    ----------
    cluster : Cluster
    """

    responses = cluster.terminate()
    # Just check the state
    log.info('Responses from terminate: ')
    for response in responses:
        pp.pprint(response)

    return


#######################################################################


# cluster
@task
def push_pyEnv(cluster):
    """ Push any local python packages to the newly started cluster and pip3 install them. This is needed when local changes to the plotting
    routines exist. The cluster may not have the updated version.

    Parameters
    ----------
    cluster : Cluster

    Notes
    -----
    Use python3 setup.py sdist to create the distributable source package to upload.

    """

    hosts = cluster.getHosts()

    for host in hosts:

        log.info(f"push_pyEnv host is {host}")

        # Push and install anything in dist folder
        dists = glob.glob(f'{curdir}/../dist/*.tar.gz')
        for dist in dists:
            log.info(f"pushing python dist: {dist}")
            subprocess.run(["scp", dist, f"{host}:~"], stderr=subprocess.STDOUT)

            path, lib = os.path.split(dist)
            log.info(f"push_pyEnv installing module: {lib}")

            subprocess.run(["ssh", host, "pip3", "install", "--upgrade", "--user", lib], stderr=subprocess.STDOUT)
    return


#####################################################################


# cluster
# @task(max_retries=0, retry_delay=timedelta(seconds=10))
@task
def start_dask(cluster) -> Client:
    """ Create a Dask cluster on the remote or local host

    Parameters
    ----------
    cluster : Cluster

    Returns
    -------
    daskclient : Dask distributed.Client
        The connected Dask Client to use for submitting jobs
    """
    # TODO: Refactor this, make Dask an optional part of the cluster
    # TODO: scale this to multiple hosts

    # Only single host supported currently
    host = cluster.getHostsCSV()

    # Should this be specified in the Job? Possibly?
    # nprocs = cluster.nodeCount * cluster.PPN
    nprocs = cluster.PPN

    # Start a dask scheduler on the host
    port = "8786"

    log.info(f"host is {host}")

    if host == '127.0.0.1':
        log.info(f"in host == {host}")
        proc = subprocess.Popen(["dask-scheduler", "--host", host, "--port", port],
                                # stderr=subprocess.DEVNULL)
                                stderr=subprocess.STDOUT)
        cluster.setDaskScheduler(proc)

        wrkrproc = subprocess.Popen(["dask-worker", "--nprocs", str(nprocs), "--nthreads", "1",
                                     f"{host}:{port}"], stderr=subprocess.STDOUT)
        cluster.setDaskWorker(wrkrproc)

        daskclient = Client(f"{host}:{port}")
        return daskclient

    else:
        # Use dask-ssh instead of multiple ssh calls
        interval=10
        maxtries=12
        num=0

        while num < maxtries:
            log.info('Pinging ssh service on remote host ... ')
            tryssh = subprocess.run(["ssh", host, "ls"], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            if tryssh.returncode == 0:
                break
            #print(tryssh.stdout) 
            log.info(f'Host not ready, sleeping for {interval} seconds ... {num}')
            time.sleep(interval)
            num += 1
            if (num + 1) == maxtries:
                log.exception(f'Unable to ssh to host {host}')
                raise signals.FAIL()
 
        try:
            log.info('Starting dask and connecting a client ...')
            proc = subprocess.Popen(["dask-ssh", "--nprocs", str(nprocs), "--scheduler-port", port, host],
                                    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            # Keep a reference to this process so we can kill it later
            cluster.setDaskScheduler(proc)
            time.sleep(interval)
        except Exception as e:
            log.info("In start_dask during subprocess.Popen :" + str(e))
            traceback.print_stack()
            raise signals.FAIL()

        daskclient = Client(f"{host}:{port}")

        return daskclient


#####################################################################


# dask
@task
def dask_client_close(daskclient: Client):
    """ Close the Dask Client

    Parameters
    ----------
    daskclient : Dask distributed.Client
    """
    daskclient.close()
    return


