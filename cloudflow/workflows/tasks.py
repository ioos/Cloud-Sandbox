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
from distributed import Client

from prefect import task

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

__copyright__ = "Copyright © 2026 Tetra Tech, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

pp = pprint.PrettyPrinter()
debug = False

log = logging.getLogger('workflow')

# Scratch disk
##############

@task
def create_scratch(provider: str, cluster: Cluster, job: Job) -> ScratchDisk:
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

    ### calls the object __init__
    if provider == 'FSx':
        scratch = FSxScratchDisk(cluster, job)
    elif provider == 'NFS':
        scratch = NFSScratchDisk(cluster, job)
    elif provider == 'Local':
        log.error('Coming soon ...')
        return
    elif provider == 'None':
        log.info('No scratch disk being used')
        return
    else:
        log.error('Unsupported provider')
        return

    log.debug(f"Creating scratch drive {provider}") 
    scratch.create()
    return scratch


@task
def scratch_remote_mount(scratch: ScratchDisk, cluster: Cluster, job: Job):
    """ Mounts the scratch disk on each node of the cluster

    Parameters
    ----------
    scratch : ScratchDisk
      The scratch disk object
    cluster : Cluster
      The cluster object that contains the hostnames and tags
    """ 


    if isinstance(scratch, ScratchDisk):
        log.info("Attempting to mount scratch disk on compute nodes...")
        hosts = cluster.getHosts()
        log.debug(f"cluster.hosts: {hosts}")
        scratch.remote_mount(hosts)

    return


@task
def delete_scratch(scratch: ScratchDisk):
    """ Unmounts and deletes the scratch disk
    
    Parameters
    ----------
    scratch : ScratchDisk
      The scratch disk object
    """
    if isinstance(scratch, ScratchDisk):
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
    Exception
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
        raise Exception('storage service not supported yet')
    else:
        log.error('Unsupported storage provider')
        raise Exception('Unsupported storage provider')

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

    APP = job.APP

    if APP == "liveocean":
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

    APP = job.APP

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

    log.debug(f"DEBUG: in tasks job_init configfile: {configfile}")

    print('in job init')
    factory = JobFactory()
    job = factory.job(configfile, NPROCS)
    print(job)
    return job


# cluster, job
@task
def simple_run(cluster: Cluster, job: Job):
    """ Run the forecast

    Parameters
    ----------
    cluster : Cluster
        The cluster to run on
    job : Job
        The job to run
    """

    # Easier to read
    APP = job.APP
    PPN = cluster.PPN
    NPROCS = job.NPROCS

    #CDATE = job.CDATE
    #HH = job.HH
    #OUTDIR = job.OUTDIR

    SAVEDIR = getattr(job, "SAVEDIR", 'none')
    RUNDIR = job.RUNDIR
    INPUTFILE = getattr(job, "INPUTFILE", 'none')
    EXEC = job.EXEC

    PTMP = getattr(job, "PTMP", 'none')

    try:
        HOSTS = cluster.getHostsCSV()
# fix generic exception
    except Exception as e:
        log.exception('In simple_run: execption retrieving list of hostnames:' + str(e))
        raise Exception('FAILED')

    runscript = f"{curdir}/simple_launcher.sh"

    try:
        if APP in ('necofs_cold', 'necofs_hot', 'necofs'):

        # export APP=$1
        # export HOSTS=$2
        # export NPROCS=$3
        # export PPN=$4
        # export SAVEDIR=$5
        # export RUNDIR=$6
        # export INPUTFILE=$7
        # export EXEC=$8

            args = [ runscript, APP, HOSTS, str(NPROCS), str(PPN), SAVEDIR, RUNDIR, INPUTFILE, EXEC ]
            result = subprocess.run(args, stderr=subprocess.STDOUT, universal_newlines=True)
        else:
            raise Exception(f"ERROR: don't know how to run {APP}")
# fix double logging
        if result.returncode != 0:
            log.exception(f'Forecast failed ... result: {result.returncode}')
            raise Exception(f'Forecast failed ... result: {result.returncode}')

    except Exception as e:
        # Using "In something:" is unneccessary as the logger outputs %(module)s.%(funcName)s
        log.exception('Exception during subprocess.run :' + str(e))
        raise Exception('Exception during subprocess.run :' + str(e))

    log.info('Forecast finished successfully')

    return



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

    # Easier to read
    PPN = cluster.PPN
    CDATE = job.CDATE
    HH = job.HH
    APP = job.APP
    NPROCS = job.NPROCS
    OUTDIR = job.OUTDIR

    SAVEDIR = getattr(job, "SAVEDIR", 'none')
    PTMP = getattr(job, "PTMP", 'none')

    # for secofs
    NSCRIBES = getattr(job, "NSCRIBES", '')

    runscript = f"{curdir}/fcst_launcher.sh"

    try:
        HOSTS = cluster.getHostsCSV()
    except Exception as e:
        log.exception('execption retrieving list of hostnames:' + str(e))
        raise Exception('FAILED')

    try:

        if APP == "adnoc":
            time.sleep(60)
            result = subprocess.run([runscript, CDATE, HH, OUTDIR, SAVEDIR, PTMP, str(NPROCS), str(PPN), HOSTS, APP, job.EXEC], stderr=subprocess.STDOUT, universal_newlines=True)
        else:
            result = subprocess.run([runscript, CDATE, HH, OUTDIR, SAVEDIR, PTMP, str(NPROCS), str(PPN), HOSTS, APP, job.EXEC, NSCRIBES], stderr=subprocess.STDOUT, universal_newlines=True)

# Fix double logging and generic exception,
        # text=True,
        # stdout=subprocess.PIPE,
        # stderr=subprocess.STDOUT,
        # check=True
        # use result.stdout as needed
# except subprocess.CalledProcessError as e:
#     log.exception(
#         "Subprocess failed: rc=%s cmd=%r output=%s",
#        e.returncode, e.cmd, (e.stdout or "").strip()
#     )
#     raise

        if result.returncode != 0:
            log.exception(f'Forecast failed ... result: {result.returncode}')
            raise Exception(f'Forecast failed ... result: {result.returncode}')

    except Exception as e:
        log.exception('Exception during subprocess.run :' + str(e))
        raise Exception('Exception during subprocess.run :' + str(e))

    log.info('Forecast finished successfully')

    curfcst=f"{job.COMROT}/current.fcst"
    with open(curfcst, 'w') as cf:
        cf.write(f"{APP}.{CDATE}{HH}\n")

    return



@task
def ufs_run(cluster: Cluster, job: Job):
    """ Run the ufs

    Parameters
    ----------
    cluster : Cluster
        The cluster to run on
    job : Job
        The job to run
    """

    PPN = cluster.PPN
    APP = job.APP
    TESTNAME = job.TESTNAME
    NPROCS = job.NPROCS
    OUTDIR = job.OUTDIR

    SAVEDIR = getattr(job, "SAVEDIR", 'none')
    PTMP = getattr(job, "PTMP", 'none')

    runscript = f"{curdir}/ufs_launcher.sh"

    try:
        HOSTS = cluster.getHostsCSV()
    except Exception as e:
        log.exception('execption retrieving list of hostnames:' + str(e))
        raise Exception('FAILED')

    try:  
        result = subprocess.run([runscript, OUTDIR, SAVEDIR, PTMP, str(NPROCS), str(PPN), HOSTS, APP, job.EXEC, NSCRIBES], stderr=subprocess.STDOUT, universal_newlines=True)

        if result.returncode != 0:
            log.exception(f'UFS failed ... result: {result.returncode}')
            raise Exception(f'UFS failed ... result: {result.returncode}')

    except Exception as e:
        log.exception('Exception during subprocess.run :' + str(e))
        raise Exception('Exception during subprocess.run :' + str(e))

    log.info('UFS finished successfully')

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

    SDATE = getattr(job,"SDATE", job.CDATE)
    EDATE = getattr(job,"EDATE", job.CDATE)
    HH = getattr(job,"HH", "00")
    APP = job.APP
    NPROCS = job.NPROCS
    XTRA_ARGS = ""

    SAVEDIR = getattr(job, "SAVEDIR", 'none')

    PTMP = getattr(job, "PTMP", 'none')

    # Use an environment variable for FSx signal

    if APP == "secofs":
       XTRA_ARGS = getattr(job, "NSCRIBES", '')

    runscript = f"{curdir}/fcst_launcher.sh"
    print(f"In hindcast_run_multi: runscript: {runscript}")

    try:
        HOSTS = cluster.getHostsCSV()
    except Exception as e:
        log.exception('execption retrieving list of hostnames:' + str(e))
        raise

    job.CDATE = SDATE

    while job.CDATE <= EDATE:

        print(f'In hindcast run multi: job.CDATE: {job.CDATE}')

        # Create ocean in file
        print(f"Calling job.make_oceanin() for {APP}")
        job.make_oceanin()

        if APP == "eccofs":
            XTRA_ARGS = getattr(job, "OCEANIN", '')

        OUTDIR = job.OUTDIR

        try:
            print('Launching model run ...')
            # TODO: too many script levels?
            # TODO: where should this be encapsulated? 
            # Maybe do it in python instead of bash, can have named arguments or use args**
            result = subprocess.run([runscript, job.CDATE, HH, OUTDIR, SAVEDIR, PTMP, str(NPROCS), str(PPN), HOSTS, APP, job.EXEC, XTRA_ARGS], stderr=subprocess.STDOUT, universal_newlines=True)

            if result.returncode != 0:
                log.exception(f'Forecast failed ... result: {result.returncode}')
                raise Exception('Forecast failed')

        except Exception as e:
            log.exception('Exception during subprocess.run :' + str(e))
            raise Exception('FAILED') from e

        # Set the date for the next day run
        # TODO: most hindcasts don't run for a single day at a time (exception LiveOcean)
        # It depends on restart state availability and other factors
        # Take on a case by case basis, perhaps add the increment to task argument or embed in the job
        job.CDATE = util.ndate(job.CDATE, 1)

    # end of while loop
    return

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
    APP = job.APP
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
        log.exception('Exception retrieving list of hostnames:' + str(e))
        raise Exception('Exception retrieving list of hostnames') from e

    try:
        result = subprocess.run([runscript, YYYY, ProjectHome, str(NPROCS), str(PPN), HOSTS, CONFIG, GRID, APP], universal_newlines=True, stderr=subprocess.STDOUT)

        if result.returncode != 0:
            log.exception(f'Forecast failed ... result: {result.returncode}')
            raise Exception('Forecast failed') from e
# fix double logging and generic 
    except Exception as e:
        log.exception('Exception during subprocess.run :' + str(e))
        raise Exception('Exception during subprocess.run') from e

    log.info('Forecast finished successfully')

###############################################################################
# python dask experiment run implementation
@task
def python_dask_experiment_run(dask_address, job):
    """ Run the dask python function

    Parameters
    ----------
    dask_address : dask_address
        The dask scheduler address on the head node to run the dask client
    job : Job
        The job to run
    """

    # Easier to read the user
    # defined variables withing
    # the Python job class reading
    # in the job configuration file
    APP = job.APP
    SCRIPT = job.SCRIPT

    # Dask Method #1 - client.map (Data Parallelism)
    # Use this when you have an iterable (a list of tasks, a list of files, or a list of parameters)
    # and you want to run the same function on every item in that list simultaneously across your AWS workers.

    # Dask Method #2 - client.submit (Task Parallelism)
    # Use this when you have a single unit of work to send to the cluster. Do not save files
    # within the function that you're using dask parallelism for. Instead, return the data
    # to the dask client here and save the file (limitation is RAM on head node)


    # This code logic below ensures the client session closes locally
    # but the scheduler on the Head Node stays alive until termination
    # workflow is implemented.
    with Client(dask_address) as client:
        log.info(f"Cluster resources: {client.scheduler_info(n_workers=-1)['workers'].keys()}")
        try:
            # Users insert an elif statement here for your dask job to run with
            # the respective workflow convention following the task or data
            # parallelism examples 

            if(job.APP == 'dask_task_parallelism_example'):
                # Upload script to the dask scheduler to be distributed to workers
                client.upload_file(job.SCRIPT)

                # Dask client needs your Python script main function imported here!
                # The python script is expected to be located in the 
                # Cloud-Sandbox/cloudflow/workflows directory for this logic to work
                from python_examples import dask_task_parallelism_example

                log.info("Running Python dask task parallelism example")

                # Dask client maps out the Python function to execute to all workers
                # and includes the required functional arguments
                futures = client.submit(dask_task_parallelism_example,int(job.ARG1))

                # Dask client gathers the results from all workers based on what
                # is suppose to be returned by the Python function.
                results = client.gather(futures)

                # User job argument in this case is the output directory pathway
                # and ensure absolute path is defined so dask workers and scheduler
                # can properly place output on the head node EFS volume
                output_dir = os.path.abspath(job.ARG2)

                # Create the directory, and do nothing if it already exists
                os.makedirs(output_dir, exist_ok=True)

                # Convert to results to dataset that was returned by the dask
                # workers computations and save the dataframe to the EFS
                # hardware by the dask client
                ds_to_save = results.to_dataset(name='AORC_partial_data_gap')
                output_path = os.path.join(output_dir, f"aorc_gap_mask_{job.ARG1}.nc")
                ds_to_save.to_netcdf(output_path)
                log.info(f"✅ Saved AORC masked year {job.ARG1} to {output_path}")

            elif(job.APP == 'dask_data_parallelism_example'):
                # Upload script to the dask scheduler to be distributed to workers
                client.upload_file(job.SCRIPT)

                # Dask client needs your Python script main function imported here!
                # The python script is expected to be located in the
                # Cloud-Sandbox/cloudflow/workflows directory for this logic to work
                from python_examples import dask_data_parallelism_example

                # Create some dummy files for dask workers to handle as part of the
                # example here for data parallelism
                file_list = [f"sensor_{str(i).zfill(3)}" for i in range(0, 20 + 1)]

                # User job argument in this case is the output directory pathway
                # and ensure absolute path is defined so dask workers and scheduler
                # can properly place output on the head node EFS volume
                output_dir = os.path.abspath(job.ARG1)

                # Create the directory, and do nothing if it already exists
                os.makedirs(output_dir, exist_ok=True)

                log.info(f"output directory is {output_dir}")

                # Dask client maps out the Python function to execute to all workers
                # and includes the required functional arguments
                futures = client.map(dask_data_parallelism_example,file_list,output_root=output_dir)

                # Dask client gathers the results from all workers based on what
                # is suppose to be returned by the Python function.
                results = client.gather(futures)

                # Print file outputs that were saved from dask workers.
                for r in results:
                    print(r)

        # Exception handler to kill dask job for Prefect3
        except Exception as e:
            log.error(f"Error during Dask execution: {e}")
            raise

        # Get the dask worker logs for users to look at the log file
        # that was output on rank 0 to see the progress of their 
        # Python workflow they've developed and for debugging
        log.info("Fetching logs from AWS workers...")
        worker_logs = client.get_worker_logs()

        # Print the output of the dask workers as part of
        # the cloudflow logging output for users
        for worker, logs in worker_logs.items():
            for level, msg in logs:
                # We filter for 'INFO' and above to avoid noise
                if level in ["INFO", "WARNING", "ERROR"]:
                    log.info(f"[{worker}] {msg}")



###############################################################################
# model experiment run implementation

@task
def experiment_run(cluster: Cluster, job: Job):
    """ Run the model experiment

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
    MODEL = job.MODEL
    JOBTYPE = job.jobtype
    APP = job.APP
    NPROCS = job.NPROCS
    EXEC = job.EXEC

    # Model dependent variable, but not required
    # for Python execution, so catch it here
    if(MODEL=='PYTHON'):
        try:
            MODEL_DIR = job.MODEL_DIR
        except:
            MODEL_DIR = 'None'
    else:
        # If not Python model, then this job
        # class variable is required
        MODEL_DIR = job.MODEL_DIR

    # experiment shell launcher script
    runscript = f"{curdir}/experiment_launcher.sh"
    print(f'runscript: {runscript}')

    # Extract the AWS cloud cluster environment
    # information to inform the compilers the 
    # information of the cluster's environment
    # for the given model execution
    try:
        HOSTS = cluster.getHostsCSV()
    except Exception as e:
        log.exception('Exception retrieving list of hostnames:' + str(e))
        raise Exception('Exception retrieving list of hostnames') from e

    ###### If a new model requires more arguments than just simply the  ######
    ###### model executable and location of model run directory, then   ######
    ###### a user will need to add a elif block of code to specify the  ######
    ###### extra option/s in the launcher script and include that extra ######
    ###### argument within the launcher script itself as well           ######
    
   
    # SCHISM needs to know the number of scribes as well
    # for it's model execution, so we have a special section
    if(JOBTYPE=='schism_experiment' and APP=='basic'):
        NSCRIBES = job.NSCRIBES
        try:
            result = subprocess.run([runscript, str(JOBTYPE), str(APP), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(NSCRIBES)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'SCHISM basic model run failed ... result: {result.returncode}')
                raise Exception('SCHISM basic model run failed')

        except Exception as e:
            log.exception('Exception during subprocess.run :' + str(e))
            raise Exception('Exception during subprocess.run')

        log.info('SCHISM basic model run finished successfully')

    # For DFlow FM model execution, we will need to define and append the location of
    # the model library suite within the shell launcher script to properly run the model
    elif(JOBTYPE=='dflowfm_experiment' and APP=='basic'):
        DFLOW_LIB = job.DFLOW_LIB
        try:
            result = subprocess.run([runscript, str(JOBTYPE), str(APP), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(DFLOW_LIB)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'DFlowFM basic model run failed ... result: {result.returncode}')
                raise Exception('DFlowFM basic model run failed')

        except Exception as e:
            log.exception('Exception during subprocess.run :' + str(e))
            raise Exception('Exception during subprocess.run')

        log.info('DFlowFM basic model run finished successfully')

    # For ROMS model execution, we need to know the name and location of the
    # master file ".in" input that tells ROMS the model run configuration
    elif(JOBTYPE=='roms_experiment' and APP=='basic'):
        IN_FILE = job.IN_FILE
        try:
            result = subprocess.run([runscript, str(JOBTYPE), str(APP), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(IN_FILE)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'ROMS basic model run failed ... result: {result.returncode}')
                raise Exception('ROMS basic model run failed')

        except Exception as e:
            log.exception('Exception during subprocess.run :' + str(e))
            raise Exception('Exception during subprocess.run')

        log.info('ROMS basic model run finished successfully')

    # For UCLA ROMS model, we need to know the "*.in" file name and location
    # as well as the number of cores to run their grid methodology
    elif(JOBTYPE=='roms_experiment' and APP=='ucla-roms'):
        IN_FILE = job.IN_FILE
        RUNCORES = job.RUNCORES
        try:
            result = subprocess.run([runscript, str(JOBTYPE), str(APP), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(IN_FILE), str(RUNCORES)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'UCLA ROMS model run failed ... result: {result.returncode}')
                raise Exception('UCLA ROMS model run failed')

        except Exception as e:
            log.exception('Exception during subprocess.run :' + str(e))
            raise Exception('Exception during subprocess.run')

        log.info('UCLA ROMS model run finished successfully')

    # For FVCOM baseline model execution, we need to know the casename
    # of the master .nml file that tells FVCOM the model run configuration
    elif(JOBTYPE=='fvcom_experiment' and APP=='basic'):
        CASE_FILE = job.CASE_FILE
        try:
            result = subprocess.run([runscript, str(JOBTYPE), str(APP), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(CASE_FILE)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'FVCOM basic model run failed ... result: {result.returncode}')
                raise Exception('FVCOM basic model run failed')

        except Exception as e:
            log.exception('Exception during subprocess.run :' + str(e))
            raise Exception('Exception during subprocess.run')

        log.info('FVCOM basic model run finished successfully')

    # For Python baseline model execution, we need to know the pathway
    # to the Python script name in order to execute it on cloudflow
    elif(JOBTYPE=='python_experiment' and APP=='basic'):
        SCRIPT = job.SCRIPT
        try:
            result = subprocess.run([runscript, str(JOBTYPE), str(APP), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(SCRIPT)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'PYTHON basic script execution failed ... result: {result.returncode}')
                raise Exception('PYTHON basic script execution failed')

        except Exception as e:
            log.exception('Exception during subprocess.run :' + str(e))
            raise Exception('Exception during subprocess.run')

        log.info('PYTHON basic script execution finished successfully')

    # For Python baseline model execution, we need to know the pathway
    # to the Python script name in order to execute it on cloudflow
    elif(JOBTYPE=='python_experiment' and APP=='mpi'):
        SCRIPT = job.SCRIPT
        try:
            result = subprocess.run([runscript, str(JOBTYPE), str(APP), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC), str(SCRIPT)], universal_newlines=True, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                log.exception(f'PYTHON mpi script execution failed ... result: {result.returncode}')
                raise Exception('PYTHON mpi script execution failed')

        except Exception as e:
            log.exception('Exception during subprocess.run :' + str(e))
            raise Exception('Exception during subprocess.run')

        log.info('PYTHON mpi script execution finished successfully')


    # Basic setup for a model run if the model simply only needs the
    # location of the model run directory and its executable
    else:
        if(APP=='basic'):
            try:
                result = subprocess.run([runscript, str(JOBTYPE), str(APP), str(NPROCS), str(PPN), HOSTS, str(MODEL_DIR), str(EXEC)], universal_newlines=True, stderr=subprocess.STDOUT)

                if result.returncode != 0:
                    log.exception(f'{JOBTYPE} basic model run failed ... result: {result.returncode}')
                    raise Exception(f'{JOBTYPE} basic model run failed')

            except Exception as e:
                log.exception('Exception during subprocess.run :' + str(e))
                raise Exception('Exception during subprocess.run')

            log.info(f'{JOBTYPE} basic model run finished successfully')

        else:
            log.exception(f'{MODEL} model jobtype {JOBTYPE} and application {APP} workflow not found.')
            raise Exception(f'{MODEL} model jobtype {JOBTYPE} and application {APP} workflow not found.')

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
            raise Exception(f'{pyfile} returned non zero exit')

    except Exception as e:
        log.exception(f'{pyfile} caused an exception ...')
        traceback.print_stack()
        raise Exception('Exception during subprocess.run') from e

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

    arg1 = job.INDIR
    arg2 = job.APP
    arg3 = job.HH 
 
    curdir = os.getcwd()
    os.chdir(localtmp)
    try:
        result = subprocess.run(['python3', pyfile, arg1, arg2, arg3], stderr=subprocess.STDOUT)
        if result.returncode != 0:
            raise Exception(f'{pyfile} returned non zero exit ...')

    except Exception as e:
        log.exception(f'{pyfile} caused an exception ...')
        traceback.print_stack()
        raise Exception('')

    os.chdir(curdir)

    return


if __name__ == '__main__':
    pass
#####################################################################
