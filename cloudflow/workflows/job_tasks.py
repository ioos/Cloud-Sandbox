"""
Collection of Job related functions wrapped as Prefect Tasks
"""
# Python dependencies
import logging
import subprocess
import sys
import os
import glob
import shutil

from distributed import Client
from prefect.engine import signals
from prefect import task

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

curdir = os.path.dirname(os.path.abspath(__file__))

from cloudflow.job.Job import Job
from cloudflow.plotting import plot_roms

from cloudflow.plotting import plot_fvcom
from cloudflow.plotting import shared as plot_shared
from cloudflow.utils import modelUtil as util
from cloudflow.workflows import getICsNOSOFS

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"

debug = False
log = logging.getLogger('workflow')

@task
def ncfiles_glob(SOURCE, filespec: str = "*.nc"):
    """ Provides a list of files that match the parameters

    Parameters
    ----------
    SOURCE : str
        A pathname to the files

    filespec : str
        A regular expression of the files to include

    Returns
    -------
    FILES : list of str
        A list of files located at SOURCE that match the filespec
    """
    FILES = sorted(glob.glob(f'{SOURCE}/{filespec}'))
    for f in FILES:
        log.info('found the following files:')
        print(f)
    return FILES


@task
def ncfiles_from_Job(job: Job):
    """ Provides a list of files that match the parameters provided by the Job object

    Parameters
    ----------
    job : Job
        The Job object. Must contain SOURCE and filespec attributes.

    Returns
    -------
    FILES : list of str
        A list of files located at SOURCE that match the filespec
    """
    SOURCE = job.INDIR
    filespec = job.FSPEC
    FILES = sorted(glob.glob(f'{SOURCE}/{filespec}'))
    return FILES

@task
def com2ptmp(job: Job):
    """ Transfer completed run from scratch disk to com 

    Parameters
    ----------
    job : Job
        The Job object with CDATE, PTMP, and COMROT attributes set.
    """

    # It takes 20 minutes to copy liveocean data from ptmp to /com 132GB 
    # If done in the cluster ~$5.18 of compute cost, do it in the head node instead
    # NOS does it in the forecast script and renames the files in the process 
    if job.APP == "liveocean":
        fdate = util.lo_date(job.CDATE)
        ptmp = f'{job.PTMP}/liveocean/{fdate}/*'
        comout = job.COMROT + '/liveocean/' + fdate

        if debug:
            print(f"ptmp: {ptmp}, comout: {comout}")

        try:
            cmd = f'mv {comout} {ptmp}'
            result = subprocess.run(cmd, universal_newlines=True, shell=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            if result.returncode != 0:
                log.error(result.stdout)
                log.error(f'error moving data from {ptmp} to {comout}')
        except Exception as e:
            log.exception(result.stdout)
            log.exception(f'exception moving data from {ptmp} to {comout}')
            raise signals.FAIL()
    elif job.APP == "secofs":
        log.debug(f"Copying data to {job.PTMP}")

        comout = job.OUTDIR
        try:
            cmd = f'cp -Rp {comout}/* {job.PTMP}/'
            result = subprocess.run(cmd, universal_newlines=True, shell=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            if result.returncode != 0:
                log.error(result.stdout)
                log.error(f'error copying data')
        except Exception as e:
            log.exception(result.stdout)
            log.exception(f'exception copying data')
            raise signals.FAIL()
    else:
        log.info("Skipping ... NOSOFS does this in the forecast script, other modes not implemented")
        pass

    return



@task
def ptmp2com(job: Job):
    """ Transfer completed run from scratch disk to com 

    Parameters
    ----------
    job : Job
        The Job object with CDATE, PTMP, and COMROT attributes set.
    """
    
    # It takes 20 minutes to copy liveocean data from ptmp to /com 132GB 
    # If done in the cluster ~$5.18 of compute cost, do it in the head node instead
    # NOS does it in the forecast script and renames the files in the process 
    if job.APP == "liveocean":
        fdate = util.lo_date(job.CDATE)
        ptmp = f'{job.PTMP}/liveocean/{fdate}/*'
        comout = job.COMROT + '/liveocean/' + fdate

        if debug:
            print(f"ptmp: {ptmp}, comout: {comout}")

        try:
            cmd = f'mv {ptmp} {comout}'
            result = subprocess.run(cmd, universal_newlines=True, shell=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            if result.returncode != 0:
                log.error(result.stdout)
                log.error(f'error moving data from {ptmp} to {comout}')
        except Exception as e:
            log.exception(result.stdout)
            log.exception(f'exception moving data from {ptmp} to {comout}')
            raise signals.FAIL()

    elif job.APP == "secofs":

        comout = job.OUTDIR
        log.debug(f"Copying output data from {job.PTMP} to {comout}")
        try:
            cmd = f'cp -Rp --update {job.PTMP}/* {comout}'
            log.debug(f"Running: {cmd}")
            result = subprocess.run(cmd, universal_newlines=True, shell=True,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            if result.returncode != 0:
                log.error(result.stdout)
                log.error(f'error copying data')
        except Exception as e:
            log.exception(result.stdout)
            log.exception(f'exception copying data')
            raise signals.FAIL()

    else:
        log.info("Skipping ... NOSOFS does this in the forecast script")
        pass

    return


@task
def baseline_from_Job(job: Job):
    """ Provides a list of the verification files that match the parameters provided by the Job object

    Parameters
    ----------
    job : Job
        The Job object. Must contain SOURCE and filespec attributes.

    Returns
    -------
    FILES : list of str
        A list of files located at SOURCE that match the filespec
    """

    SOURCE = job.VERIFDIR
    filespec = job.FSPEC
    FILES = sorted(glob.glob(f'{SOURCE}/{filespec}'))
    return FILES


@task
def get_baseline(job: Job, sshuser=None):
    """ Retrieve operational forecast files for comparison to quasi-operational forecasts

    Parameters
    ----------
    job : Job
        The Job object.

    sshuser : str
        The user and host to use for retrieving data from a remote server. Required for LiveOcean.
    """

    cdate = job.CDATE
    app = job.APP
    vdir = job.VERIFDIR
    hh = job.HH

    if app == 'liveocean':
        try:
            util.get_baseline_lo(cdate, vdir, sshuser)
        except Exception as e:
            log.exception(f'Retrieving baselines failed ...')
            raise signals.FAIL()
    elif app in util.nosofs_models:
        script = f"{curdir}/scripts/getNomadsProd.sh"

        result = subprocess.run([script, app, cdate, hh, vdir], stderr=subprocess.STDOUT)
        if result.returncode != 0:
            log.exception(f'Retrieving baselines failed ... result: {result.returncode}')
            raise signals.FAIL()
    else:
        log.exception(f'{app} is not supported')
        raise signals.FAIL()
    return


@task
def get_forcing(job: Job, sshuser=None):
    """ Retrieve operational moddel forcing data and initial conditions

    Parameters
    ----------
    job : Job
        The Job object.

    sshuser : str
        The user and host to use for retrieving data from a remote server. Required for LiveOcean.
    """

    app = job.APP

    sdate = getattr(job,"SDATE", job.CDATE)
    edate = getattr(job,"EDATE", job.CDATE)
    hh = getattr(job,"HH", "00")

    comrot = job.COMROT

    if app == 'liveocean':

        comdir = job.OUTDIR    # ex: /com/liveocean/f2020.MM.DD

        # /mnt/efs/fs1/com/ec2-user/LO_output/forcing/cas7
        #frcdir = job.COMROT + '/liveocean'
        # TODO: hardcode for now, fix it later
        # TODO: hardcode for now, fix it later
        # TODO: hardcode for now, fix it later
        frcdir = job.COMROT + '/LO_output/forcing/cas7'

        cdate = sdate
        while cdate <= edate:

            try:
                # TODO: hardcodde for now, parameterize later
                util.get_ICs_lo_cas7_hindcast(cdate, frcdir, sshuser)
            except Exception as e:
                log.exception('Problem encountered with downloading forcing data ...')
                raise signals.FAIL()

            cdate = util.ndate(cdate, 1)

    # ROMS and FVCOM NOSOFS models
    elif app in util.nosofs_models:

        cdate = sdate

        while cdate <= edate:

            comdir = f"{comrot}/{app}.{cdate}"
            try:
                getICsNOSOFS.getICs(cdate, hh, app, comdir)
            except Exception as e:
                log.exception('Problem encountered with downloading forcing data ...')
                raise signals.FAIL()

            cdate = util.ndate(cdate, 1)

    elif app in ('secofs', 'eccofs', 'necofs'):
        print(f"only using pre-downloaded forcing files for {app} test case")
    else:
        log.error(f"Unsupported forecast: {app}")
        raise signals.FAIL()

    return

@task
def old_get_forcing(job: Job, sshuser=None):
    """ Retrieve operational moddel forcing data and initial conditions

    Parameters
    ----------
    job : Job
        The Job object.

    sshuser : str
        The user and host to use for retrieving data from a remote server. Required for LiveOcean.
    """

    cdate = job.CDATE
    app = job.APP
    comrot = job.COMROT
    hh = job.HH

    comdir = job.OUTDIR    # ex: /com/liveocean/f2020.MM.DD

    # Coupled WRF/ROMS
    if app == 'wrfroms':
        #comdir = f"{comrot}/{app}/{cdate}"
        script = f"{curdir}/scripts/getICsWRFROMS.sh"

        result = subprocess.run([script, cdate, comdir], stderr=subprocess.STDOUT)
        if result.returncode != 0:
            log.exception(f'Retrieving ICs failed ... result: {result.returncode}')
            raise signals.FAIL()
    elif app == 'adcircofs':
	
        #script = f"{curdir}/fcstrun_adcirc_prep.sh"
        #result = subprocess.run([script])
        print('Not required to download forcing') 
    else:
        log.warning(f"Could not download initial conditions for {app}")

    return


@task
def daskmake_mpegs(client: Client, job: Job, diff: bool=False):
    """ Create mpegs from plots

    Parameters
    ----------
    client : distributed.Client
        The Dask Client to use for running the job

    job : Job

    diff : bool
        True - create mpegs from the difference plots
        False - create mpegs from the forecast plots
    """
    log.info(f"In daskmake_mpegs")

    if not os.path.exists(job.OUTDIR):
        os.makedirs(job.OUTDIR)

    idx = 0
    futures = []

    plot_function = plot_shared.png_ffmpeg

    # TODO: make the filespec a function parameter
    for var in job.VARS:

        if diff:
            source = f"{job.OUTDIR}/f%03d_{var}_diff.png"
            target = f"{job.OUTDIR}/{var}_diff.mp4"
        else:
            source = f"{job.OUTDIR}/f%03d_{var}.png"
            target = f"{job.OUTDIR}/{var}.mp4"

        log.info(f"Creating movie for {var}")
        log.info(f"source:{source} target:{target}")
        future = client.submit(plot_function, source, target)
        futures.append(future)
        log.info(futures[idx])
        idx += 1

    # Wait for the jobs to complete
    for future in futures:
        result = future.result()

    return


@task
def daskmake_plots(client: Client, FILES: list, job: Job):
    """ Create plots using a Dask distributed Client

    Parameters
    ----------
    client : distributed.Client
        The Dask Client to use for running the job

    FILES : list of str
        The source input files.

    job : Job
    """
    target = job.OUTDIR

    log.info(f"In daskmake_plots {FILES}")

    if not os.path.exists(target):
        os.makedirs(target)

    idx = 0
    futures = []

    plot_function : callable

    if job.APP in util.roms_models:
      plot_function = plot_roms.plot
    elif job.APP in util.fvcom_models:
      plot_function = plot_fvcom.plot


    # Submit all jobs to the dask scheduler
    for filename in FILES:
        for varname in job.VARS:
            log.info(f"plotting file: {filename} var: {varname}")
            future = client.submit(plot_function, filename, target, varname)
            futures.append(future)
            log.info(futures[idx])
            idx += 1

    # Wait for the jobs to complete
    for future in futures:
        result = future.result()

    # Was unable to get it to work using client.map() gather
    # filenames = FILES[0:1]
    # print("mapping plot_roms over filenames")
    # futures = client.map(plot_roms, filenames, pure=False, target=unmapped(target), varname=unmapped(varname))
    # print("Futures:",futures)
    # Wait for the processes to finish, gather the results
    # results = client.gather(futures)
    # print("gathered results")
    # print("Results:", results)

    return



@task
def daskmake_diff_plots(client: Client, EXPERIMENT: list, BASELINE: list, job: Job):
    """ Create difference plots using a Dask distributed Client

    Parameters
    ----------
    client : distributed.Client
        The Dask Client to use for running the job

    EXPERIMENT : list of str
        The local forecast output files.

    BASELINE : list of str
        The list of operational verification forecast output files.

    job : Job
    """

    target = job.OUTDIR

    log.info(f"In daskmake_diff_plots {EXPERIMENT}")

    log.info(f"Target is : {target}")
    if not os.path.exists(target):
        os.makedirs(target)

    idx = 0
    futures = []

    #plot_function : callable
    #vminmax : callable

    # ROMS and FVCOM grids are handled differently
    if job.APP in util.roms_models:
      plot_module = plot_roms
    elif job.APP in util.fvcom_models:
      plot_module = plot_fvcom

    baselen = len(BASELINE)
    explen  = len(EXPERIMENT)

    if baselen != explen:
        log.warning(f"BASELINE and EXPERIMENT length mismatch: BASELINE {baselen}, EXPERIMENT {explen}" )

    # Refactored this to support short experiment runs
    lastbase = BASELINE[explen-1]
    lastexp = EXPERIMENT[explen-1]

    # Loop through the variable list
    for varname in job.VARS:

        # Get the scale to use for all of the plots, use the last file in the sequence
        vmin, vmax = plot_module.get_vmin_vmax(lastbase, lastexp, varname)

        idx = 0
        while idx < explen:
            expfile  = EXPERIMENT[idx]
            basefile = BASELINE[idx]

            log.info(f"plotting diff for {expfile} {basefile} var: {varname}")
            future = client.submit(plot_module.plot_diff, basefile, expfile, target, varname, vmin=vmin, vmax=vmax)
            futures.append(future)
            log.info(futures[idx])
            idx += 1

    # Wait for the jobs to complete
    for future in futures:
        result = future.result()

    return

