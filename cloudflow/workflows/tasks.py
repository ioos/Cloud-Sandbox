"""

Module of Prefect @task annotated functions for use in cloud based numerical 
weather modelling workflows. These tasks are basically wrappers around other
functions. Prefect forces some design choices.

Keep things cloud platform agnostic at this layer.
"""

import os
import sys
import pprint
import subprocess
import glob
import logging

from prefect import task
from prefect.engine import signals

# Local dependencies

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))
curdir = os.path.dirname(os.path.abspath(__file__))

from ..job.Job import Job
from ..job.JobFactory import JobFactory
from ..cluster.Cluster import Cluster

from ..services.StorageService import StorageService
from ..services.S3Storage import S3Storage

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

pp = pprint.PrettyPrinter()
debug = False

log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)

# Storage
#######################################################################

@task
def storage_init(provider: str) -> StorageService:
    """Class factory that returns an implementation of StorageService.

    StorageService is the abstract base class that provides a generic interface for
    multiple cloud platforms.

    Parameters
    ----------
    provider : str
      Name of an implemented provider.

    Returns
    -------
    service : StorageService
      Returns a specific implementation of the StorageService interface.

    Raises
    ------
    signals.FAIL
      Triggers and exception if `provider` is not supported.

    Notes
    -----
    The following providers are implemented:
      AWS S3 - S3Storage

    """

    if provider == 'AWS':
        service = S3Storage()

    elif provider == 'Local':
        log.error('Coming soon ...')
        raise signals.FAIL()
    else:
        log.error('Unsupported provider')
        raise signals.FAIL()

    return service


#######################################################################


# Storage, Job
# TODO: Parameterize filespecs?
@task
def save_to_cloud(job: Job, service: StorageService, filespecs: list, public=False):
    """ Save stuff to cloud storage.

    Parameters
    ----------
    job : Job
      A Job object that contains the required attributes:
        BUCKET - bucket name
        BCKTFOLDER - bucket folder
        CDATE - simulation date
        OUTDIR - source path

    service : StorageService
      An implemented service for your cloud provider.

    filespecs : list of strings
      file specifications to match using glob.glob
      Example: ["*.nc", "*.png"]

    public : bool, optional
      Whether the files should be made public. Default: False
    """

    BUCKET = job.BUCKET
    BCKTFLDR = job.BCKTFLDR
    CDATE = job.CDATE
    path = job.OUTDIR

    # Forecast output
    # ocean_his_0002.nc
    # folder = f"output/{job.CDATE}"
    # filespec = ['ocean_his_*.nc']

    for spec in filespecs:

        FILES = sorted(glob.glob(f"{path}/{spec}"))

        log.info('Uploading the following files:')

        for filename in FILES:
            print(filename)
            fhead, ftail = os.path.split(filename)
            key = f"{BCKTFLDR}/{CDATE}/{ftail}"

            service.uploadFile(filename, BUCKET, key, public)
    return


#######################################################################

# cluster, job
@task
def job_init(cluster: Cluster, configfile) -> Job:
    # We can't really separate the hardware from the job, nprocs is needed
    NPROCS = cluster.nodeCount * cluster.PPN

    if debug: print(f"DEBUG: in tasks job_init configfile: {configfile}")
    # This is opposite of the way resources are usually allocated
    # Normally, NPROCs comes from the job and will use that much compute resources
    # Here, we fit the job to the desired on-demand resources.
    # TODO ?: set it up so that the best machine(s) for the job are provisioned based on the resource request.

    factory = JobFactory()
    job = factory.job(configfile, NPROCS)
    return job


#######################################################################


# cluster, job
@task
def forecast_run(cluster: Cluster, job: Job):
    PPN = cluster.getCoresPN()

    # Easier to read
    CDATE = job.CDATE
    HH = job.HH
    OFS = job.OFS
    NPROCS = job.NPROCS
    OUTDIR = job.OUTDIR
    #EXEC = job.EXEC

    runscript = f"{curdir}/fcst_launcher.sh"

    try:
        HOSTS = cluster.getHostsCSV()
    except Exception as e:
        log.exception('In driver: execption retrieving list of hostnames:' + str(e))
        raise signals.FAIL()

    try:
        result = subprocess.run([runscript, CDATE, HH, OUTDIR, str(NPROCS), str(PPN), HOSTS, OFS], \
                                stderr=subprocess.STDOUT)

        if result.returncode != 0:
            log.exception(f'Forecast failed ... result: {result.returncode}')
            raise signals.FAIL()

    except Exception as e:
        log.exception('In driver: Exception during subprocess.run :' + str(e))
        raise signals.FAIL()

    log.info('Forecast finished successfully')
    return


#######################################################################


if __name__ == '__main__':
    pass
#####################################################################
