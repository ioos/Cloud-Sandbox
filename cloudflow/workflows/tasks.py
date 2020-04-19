"""

Module of Prefect @task annotated functions for use in cloud based numerical 
weather modelling workflows. These tasks are basically wrappers around other
functions. Prefect forces some design choices.

Keep things cloud platform agnostic at this layer.
"""
print(f"file: {__file__} | name: {__name__} | package: {__package__}")

import os
import sys
import pprint
import subprocess
import glob
import logging
import traceback

from prefect import task
from prefect.engine import signals

# Local dependencies

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))
curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job
from cloudflow.job.JobFactory import JobFactory
from cloudflow.cluster.Cluster import Cluster

from cloudflow.services.StorageService import StorageService
from cloudflow.services.S3Storage import S3Storage

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

@task
def run_pynotebook(pyfile: str):

    print(f'Running {pyfile}')

    try:
        result = subprocess.run(['python3', pyfile], stderr=subprocess.STDOUT)
        if result.returncode != 0:
            log.exception(f'{pyfile} returned non zero exit ...')
            raise signals.FAIL()

    except Exception as e:
        log.exception(f'{pyfile} caused an exception ...')
        traceback.print_stack()
        raise signals.FAIL()

    print(f'Finished running {pyfile}')
    return


@task
def fetchpy_and_run(job: Job, service: StorageService):

    # WARNING!!!!! This allows arbitrary code execution!!!

    # Retrieve package to run from S3
    # .py file 
    # and a config file

    if job.OFS != 'cbofs':
        log.info('This only works for cbofs currently ... skipping')
        return

    bucket = job.BUCKET   # this is ioos-cloud-sandbox

    folder = 'cloudflow/inject'

    localtmp = f'/tmp/{folder}'
    if not os.path.exists(localtmp):
        os.makedirs(localtmp)

    # Retrieve config/job file
    configname = 'hlfs.config'
    key = f'{folder}/{configname}'
    configfile = f'{localtmp}/{configname}'

    if service.file_exists(bucket, key):
        service.downloadFile(bucket, key, configfile)
    else:
        log.info('No user supplied config file available ... skipping')
        return

    filename = 'hlfs.py'

    key = f'{folder}/{filename}'
    pyfile = f'{localtmp}/{filename}'

    if service.file_exists(bucket, key):
        service.downloadFile(bucket, key, pyfile)
    else:
        log.info('No user supplied python script available ... skipping')
        return 

    # retrieved the python and config files, run it
    curdir = os.getcwd()
    os.chdir(localtmp)
    try:
        result = subprocess.run(['python3', pyfile], stderr=subprocess.STDOUT)
        if result.returncode != 0:
            log.exception(f'{pyfile} returned non zero exit ...')
            raise signals.FAIL()

    except Exception as e:
        log.exception(f'{pyfile} caused an exception ...')
        traceback.print_stack()
        raise signals.FAIL()

    os.chdir(curdir)

    return



if __name__ == '__main__':
    pass
#####################################################################
