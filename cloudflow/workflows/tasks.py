"""
Collection of Prefect task annotated functions for use in cloud based numerical
weather modelling workflows. These tasks are basically wrappers around other
functions.

Keep things cloud platform agnostic at this layer.
"""
#print(f"file: {__file__} | name: {__name__} | package: {__package__}")
import os
import sys
import pprint
import subprocess
import glob
import time
import logging
import traceback

from prefect import task
from prefect.engine import signals
from prefect.triggers import all_finished

# Local dependencies

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job
from cloudflow.job.JobFactory import JobFactory
from cloudflow.cluster.Cluster import Cluster

from cloudflow.services.StorageService import StorageService
from cloudflow.services.S3Storage import S3Storage

from cloudflow.services.ScratchDisk import ScratchDisk
from cloudflow.services.FSxScratchDisk import FSxScratchDisk
from cloudflow.services.NFSScratchDisk import NFSScratchDisk

from cloudflow.utils import modelUtil as util

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

pp = pprint.PrettyPrinter()
debug = False

log = logging.getLogger('workflow')

# Scratch disk
##############

@task
def create_scratch(provider: str, jobconfigfile: str, mountpath: str = '/ptmp') -> ScratchDisk:
    """ Provides a high speed scratch disk if available. Creates and mounts the disk.

    Parameters
    ----------
    provider : str
      Name of an implemented provider.

    jobconfigfile : str
        The Job configuration file
      

    Returns
    -------
    scratch : ScratchDisk
      Returns the ScratchDisk object

    """

    ### PT 2/13/2025 - HERE
    if provider == 'FSx':
        scratch = FSxScratchDisk(configfile)
    elif provider == 'NFS':
        scratch = NFSScratchDisk(configfile)
    elif provider == 'Local':
        log.error('Coming soon ...')
        raise signals.FAIL('FAILED')
    else:
        log.error('Unsupported provider')
        raise signals.FAIL('FAILED')

    scratch.create(mountpath)
    return scratch


@task
def mount_scratch(scratch: ScratchDisk, cluster: Cluster):
    """ Mounts the scratch disk on each node of the cluster

    Parameters
    ----------
    scratch : ScratchDisk
      The scratch disk object
    cluster : Cluster
      The cluster object that contains the hostnames and tags
    """ 

    hosts = cluster.getHosts() 
    scratch.remote_mount(hosts)
    return


@task(trigger=all_finished)
def delete_scratch(scratch: ScratchDisk):
    """ Unmounts and deletes the scratch disk
    
    Parameters
    ----------
    scratch : ScratchDisk
      The scratch disk object
    """
    scratch.delete()
    return

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
        raise signals.FAIL('storage service not supported yet')
    else:
        log.error('Unsupported storage provider')
        raise signals.FAIL('Unsupported storage provider')

    return service


#######################################################################


# Storage, Job
@task
def save_history(job: Job, service: StorageService, filespecs: list, public=False):
    """ Save forecast history files to cloud storage. 

    Parameters
    ----------
    job : Job
      A Job object that contains the required attributes.
      BUCKET - bucket name
      BCKTFOLDER - bucket folder
      CDATE - simulation date
      OUTDIR - source path

    service : StorageService
      An implemented service for your cloud provider.

    filespecs : list of str
      file specifications to match using glob.glob
      Example: ["*.nc", "*.png"]

    public : bool, optional
      Whether the files should be made public. Default: False

    """

    BUCKET = job.BUCKET
    BCKTFLDR = job.BCKTFLDR
    CDATE = job.CDATE
    path = job.OUTDIR

    OFS = job.OFS

    if OFS == "liveocean":
        # If liveocean use fYYYY.MM.DD for folder ex. f2020.06.23
        CDATE = util.lo_date(job.CDATE)
    else:
        # We are only saving liveocean forecast output currently
        return

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


# Storage, Job
@task
def save_to_cloud(job: Job, service: StorageService, filespecs: list, public=False):
    """ Save stuff to cloud storage.

    Parameters
    ----------
    job : Job
      A Job object that contains the required attributes.
      BUCKET - bucket name
      BCKTFOLDER - bucket folder
      CDATE - simulation date
      OUTDIR - source path

    service : StorageService
      An implemented service for your cloud provider.

    filespecs : list of str
      file specifications to match using glob.glob
      Example: ["*.nc", "*.png"]

    public : bool, optional
      Whether the files should be made public. Default: False
    """

    BUCKET = job.BUCKET
    BCKTFLDR = job.BCKTFLDR
    CDATE = job.CDATE
    path = job.OUTDIR

    OFS = job.OFS

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

            # TODO If liveocean use fYYYY.MM.DD for folder ex. f2020.06.23
            key = f"{BCKTFLDR}/{CDATE}/{ftail}"

            service.uploadFile(filename, BUCKET, key, public)
    return


#######################################################################

# cluster, job
@task
def job_init(cluster: Cluster, configfile) -> Job:
    """ Initialize the Job object.
    Parameters
    ----------
    cluster : Cluster
        The Cluster object to use for this Job

    configfile : str
        The Job configuration file

    Returns
    -------
    job : Job
        An implemented sub-class of Job

    Notes
    -----
        We can't really separate the hardware from the job, nprocs is needed to setup the Job
    """
    NPROCS = cluster.nodeCount * cluster.PPN

    if debug: print(f"DEBUG: in tasks job_init configfile: {configfile}")
    # This is opposite of the way resources are usually allocated
    # Normally, NPROCs comes from the job and will use that much compute resources
    # Here, we fit the job to the desired on-demand resources.
    # TODO ?: set it up so that the best machine(s) for the job are provisioned based on the resource request.

    factory = JobFactory()
    job = factory.job(configfile, NPROCS)
    return job




# cluster, job
@task
def forecast_run(cluster: Cluster, job: Job):
    """ Run the forecast

    Parameters
    ----------
    cluster : Cluster
        The cluster to run on
    job : Job
        The job to run
    """
    PPN = cluster.getCoresPN()

    # Easier to read
    CDATE = job.CDATE
    HH = job.HH
    OFS = job.OFS
    NPROCS = job.NPROCS
    OUTDIR = job.OUTDIR
    SAVEDIR = job.SAVE

    runscript = f"{curdir}/fcst_launcher.sh"

    try:
        HOSTS = cluster.getHostsCSV()
    except Exception as e:
        log.exception('In driver: execption retrieving list of hostnames:' + str(e))
        raise signals.FAIL('FAILED')

    try:

        if OFS == "adnoc":
            time.sleep(60)
            result = subprocess.run([runscript, CDATE, HH, OUTDIR, SAVEDIR, str(NPROCS), str(PPN), HOSTS, OFS, job.EXEC], stderr=subprocess.STDOUT, universal_newlines=True)
        else:
            result = subprocess.run([runscript, CDATE, HH, OUTDIR, SAVEDIR, str(NPROCS), str(PPN), HOSTS, OFS, job.EXEC], stderr=subprocess.STDOUT, universal_newlines=True)

        if result.returncode != 0:
            log.exception(f'Forecast failed ... result: {result.returncode}')
            raise signals.FAIL(f'Forecast failed ... result: {result.returncode}')

    except Exception as e:
        log.exception('In driver: Exception during subprocess.run :' + str(e))
        raise signals.FAIL('In driver: Exception during subprocess.run :' + str(e))

    log.info('Forecast finished successfully')

    curfcst=f"{job.COMROT}/current.fcst"
    with open(curfcst, 'w') as cf:
        cf.write(f"{OFS}.{CDATE}{HH}\n")

    return

#######################################################################

# cluster, job
@task
def hindcast_run_multi(cluster: Cluster, job: Job):
    """ Run the hindcast

    Parameters
    ----------
    cluster : Cluster
        The cluster to run on
    job : Job
        The job to run
    """
    PPN = cluster.getCoresPN()

    # Easier to read
    SDATE = job.SDATE
    EDATE = job.EDATE
    HH = job.HH
    OFS = job.OFS
    NPROCS = job.NPROCS
    OUTDIR = job.OUTDIR
    SAVEDIR = job.SAVE

    runscript = f"{curdir}/fcst_launcher.sh"
    print(f"In hindcast_run_multi: runscript: {runscript}")

    try:
        HOSTS = cluster.getHostsCSV()
    except Exception as e:
        log.exception('In driver: execption retrieving list of hostnames:' + str(e))
        raise signals.FAIL('FAILED')

    job.CDATE = SDATE

    while job.CDATE <= EDATE:

        print(f'In hindcast run multi: job.CDATE: {job.CDATE}')

        # Create ocean in file
        job.make_oceanin()

        try:
            print('Launching model run ...')
            result = subprocess.run([runscript, job.CDATE, HH, job.OUTDIR, SAVEDIR, str(NPROCS), str(PPN), HOSTS, OFS, job.EXEC], stderr=subprocess.STDOUT, universal_newlines=True)

            if result.returncode != 0:
                log.exception(f'Forecast failed ... result: {result.returncode}')
                raise signals.FAIL('FAILED')

        except Exception as e:
            log.exception('In driver: Exception during subprocess.run :' + str(e))
            raise signals.FAIL('FAILED')

        # Set the date for the next day run
        job.CDATE = util.ndate(job.CDATE, 1)

    # end of while loop


###############################################################################
# cluster, job

@task
def cora_reanalysis_run(cluster: Cluster, job: Job):
    """ Run the forecast

    Parameters
    ----------
    cluster : Cluster
        The cluster to run on
    job : Job
        The job to run
    """
    PPN = cluster.getCoresPN()

    # Easier to read
    YYYY = job.YYYY
    OFS = job.OFS
    NPROCS = job.NPROCS
    ProjectHome = job.ProjectHome
    CONFIG=job.CONFIG
    GRID = job.GRID

    runscript = f"{curdir}/cora_launcher.sh"

    print(f'DEBUG: job.CONFIG: {job.CONFIG}')
    print(f'runscript: {runscript}')

    try:
        HOSTS = cluster.getHostsCSV()
    except Exception as e:
        log.exception('In driver: execption retrieving list of hostnames:' + str(e))
        raise signals.FAIL('FAILED')

    try:
        result = subprocess.run([runscript, YYYY, ProjectHome, str(NPROCS), str(PPN), HOSTS, CONFIG, GRID], universal_newlines=True, stderr=subprocess.STDOUT)

        if result.returncode != 0:
            log.exception(f'Forecast failed ... result: {result.returncode}')
            raise signals.FAIL('FAILED')

    except Exception as e:
        log.exception('In driver: Exception during subprocess.run :' + str(e))
        raise signals.FAIL('FAILED')

    log.info('Forecast finished successfully')


###############################################################################
# model baseline template

@task
def template_run(cluster: Cluster, job: Job):
    """ Run the forecast

    Parameters
    ----------
    cluster : Cluster
        The cluster to run on
    job : Job
        The job to run
    """
    PPN = cluster.getCoresPN()

    # Easier to read the user
    # defined variables withing
    # the Python job class reading
    # in the job configuration file
    OFS = job.OFS
    NPROCS = job.NPROCS
    MODEL_DIR = job.MODEL_DIR
    EXEC = job.EXEC

    # template shell launcher script
    runscript = f"{curdir}/template_launcher.sh"
    print(f'runscript: {runscript}')

    # Extract the AWS cloud cluster environment
    # information to inform the compilers the 
    # information of the cluster's environment
    # for the given model execution
    try:
        HOSTS = cluster.getHostsCSV()
    except Exception as e:
        log.exception('In driver: execption retrieving list of hostnames:' + str(e))
        raise signals.FAIL('FAILED')

    ###### If a new model requires more arguments than just simply the  ######
    ###### model executable and location of model run directory, then   ######
    ###### a user will need to add a elif block of code to specify the  ######
    ###### extra option/s in the launcher script and include that extra ######
    ###### argument within the launcher script itself as well           ######
    
   
    # SCHISM needs to know the number of scribes as well
    # for it's model execution, so we have a special section
    if(OFS=='schism'):
        NSCRIBES = job.NSCRIBES
        try:
            result = subprocess.run([runscript, str(OFS), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(NSCRIBES)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'SCHISM model run failed ... result: {result.returncode}')
                raise signals.FAIL('FAILED')

        except Exception as e:
            log.exception('In driver: Exception during subprocess.run :' + str(e))
            raise signals.FAIL('FAILED')

        log.info('SCHISM model run finished successfully')

    # For D-Flow FM model execution, we will need to define and append the location of
    # the model library suite within the shell launcher script to properly run the model
    elif(OFS=='dflowfm'):
        DFLOW_LIB = job.DFLOW_LIB
        try:
            result = subprocess.run([runscript, str(OFS), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(DFLOW_LIB)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'DFlowFM model run failed ... result: {result.returncode}')
                raise signals.FAIL('FAILED')

        except Exception as e:
            log.exception('In driver: Exception during subprocess.run :' + str(e))
            raise signals.FAIL('FAILED')

        log.info('DFlowFM model run finished successfully')

    # For ROMS model execution, we need to know the name and location of the
    # master file ".in" input that tells ROMS the model run configuration
    elif(OFS=='roms'):
        IN_FILE = job.IN_FILE
        try:
            result = subprocess.run([runscript, str(OFS), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(IN_FILE)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'ROMS model run failed ... result: {result.returncode}')
                raise signals.FAIL('FAILED')

        except Exception as e:
            log.exception('In driver: Exception during subprocess.run :' + str(e))
            raise signals.FAIL('FAILED')

        log.info('ROMS model run finished successfully')

    # For FVCOM model execution, we need to know the casename of the master
    # .nml file that tells FVCOM the model run configuration
    elif(OFS=='fvcom'):
        CASE_FILE = job.CASE_FILE
        try:
            result = subprocess.run([runscript, str(OFS), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(CASE_FILE)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'FVCOM model run failed ... result: {result.returncode}')
                raise signals.FAIL('FAILED')

        except Exception as e:
            log.exception('In driver: Exception during subprocess.run :' + str(e))
            raise signals.FAIL('FAILED')

        log.info('FVCOM model run finished successfully')

    # Template setup for a model run if the model simply only needs the executable
    # information to run the model
    else:
        try:
            result = subprocess.run([runscript, str(OFS), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'{OFS} model run failed ... result: {result.returncode}')
                raise signals.FAIL('FAILED')

        except Exception as e:
            log.exception('In driver: Exception during subprocess.run :' + str(e))
            raise signals.FAIL('FAILED')

        log.info(f'{OFS} model run finished successfully')

###############################################################################

@task
def run_pynotebook(pyfile: str):
    """ Wraps the execution of a python3 script

    Parameters
    ----------
    pyfile : The path and filename of the python3 script to run.
    """
    log.info(f'Running {pyfile}')

    try:
        result = subprocess.run(['python3', pyfile], 
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True, text=True)
        print(result.stdout)
        if result.returncode != 0:
            log.exception(f'{pyfile} returned non zero exit ...')
            traceback.print_stack()
            raise signals.FAIL('FAILED')

    except Exception as e:
        log.exception(f'{pyfile} caused an exception ...')
        traceback.print_stack()
        raise signals.FAIL('FAILED')

    return


@task
def fetchpy_and_run(job: Job, service: StorageService, notebook = ''):
    """ Prototype for injecting user developed scripts into a workflow. This is currently implemented only for the
    hlfs example. Additional work is needed to generalize this process.

    Parameters
    ----------
    job : Job
        The job configuration file

    service : StorageService
        The cloud or local storage service implementation

    notebook : str
        The S3 key of the Python script to run. 

    Notes
    -----
    WARNING!!!!! This could potentially allow arbitrary code execution!!!
                 Only run scripts that have been reviewed.
    """

    bucket = job.BUCKET   # this is ioos-cloud-sandbox

    folder = 'cloudflow/inject'
    localtmp = f'/tmp/{folder}'
    if not os.path.exists(localtmp):
        os.makedirs(localtmp)

    # Get last element of: cloudflow/inject/kenny/cloud_sandbot.py
    filename = notebook.split('/')[-1]
    pyfile = f'{localtmp}/{filename}'
    key = notebook

    if service.file_exists(bucket, key):
        service.downloadFile(bucket, key, pyfile)
    else:
        log.info('No user supplied python script available ... skipping')
        return

    # retrieved the python file, use the current job object to set up parameters/arguments

    COMDIR = job.INDIR
    OFS = job.OFS
    HH = job.HH
   
    arg1 = COMDIR
    arg2 = OFS
    arg3 = HH 
 
    curdir = os.getcwd()
    os.chdir(localtmp)
    try:
        result = subprocess.run(['python3', pyfile, arg1, arg2, arg3], stderr=subprocess.STDOUT)
        if result.returncode != 0:
            log.exception(f'{pyfile} returned non zero exit ...')
            raise signals.FAIL('FAILED')

    except Exception as e:
        log.exception(f'{pyfile} caused an exception ...')
        traceback.print_stack()
        raise signals.FAIL('FAILED')

    os.chdir(curdir)

    return


if __name__ == '__main__':
    pass
#####################################################################
