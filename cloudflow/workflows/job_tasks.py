"""
"""
# Python dependencies
import logging
import subprocess
import sys
import os
import glob
import traceback

from distributed import Client
from prefect.engine import signals
from prefect import task

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))
curdir = os.path.dirname(os.path.abspath(__file__))

from job.Job import Job

#from plotting import plot_roms
import plotting.plot_roms as plot_roms
import plotting.plot_fvcom as plot_fvcom
import plotting.shared as plot_shared
import utils.romsUtil as util

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)

# generic, should be job
@task
def ncfiles_glob(SOURCE, filespec: str = "*.nc"):
    FILES = sorted(glob.glob(f'{SOURCE}/{filespec}'))
    for f in FILES:
        log.info('found the following files:')
        print(f)
    return FILES


#####################################################################


# job
@task
def ncfiles_from_Job(job: Job):
    SOURCE = job.INDIR
    filespec = job.FSPEC
    FILES = sorted(glob.glob(f'{SOURCE}/{filespec}'))
    return FILES


#####################################################################


@task
def baseline_from_Job(job: Job):
    SOURCE = job.VERIFDIR
    filespec = job.FSPEC
    FILES = sorted(glob.glob(f'{SOURCE}/{filespec}'))
    return FILES


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
def get_forcing(job: Job, sshuser=None):
    """ job - Job object """

    # Open and parse jobconfig file
    # "OFS"       : "liveocean",
    # "CDATE"     : "20191106",
    # "ININAME"   : "/com/liveocean/f2019.11.05/ocean_his_0025.nc",

    # jobDict = util.readConfig(jobconfig)
    cdate = job.CDATE
    ofs = job.OFS
    comrot = job.COMROT
    hh = job.HH

    if ofs == 'liveocean':
        comdir = f"{comrot}/{ofs}"
        try:
            util.get_ICs_lo(cdate, comdir, sshuser)
        except Exception as e:
            log.exception('Problem encountered with downloading forcing data ...')
            raise signals.FAIL()

    # ROMS models
    elif ofs in ('cbofs', 'dbofs', 'tbofs', 'gomofs', 'ciofs'):
        comdir = f"{comrot}/{ofs}.{cdate}"
        script = f"{curdir}/../../workflows/scripts/getICsROMS.sh"

        result = subprocess.run([script, cdate, hh, ofs, comdir], stderr=subprocess.STDOUT)
        if result.returncode != 0:
            log.exception(f'Retrieving ICs failed ... result: {result.returncode}')
            raise signals.FAIL()

    # FVCOM models
    elif ofs in ('ngofs', 'nwgofs', 'negofs', 'leofs', 'sfbofs', 'lmhofs'):
        comdir = f"{comrot}/{ofs}.{cdate}"
        script = f"{curdir}/../../workflows/scripts/getICsFVCOM.sh"

        result = subprocess.run([script, cdate, hh, ofs, comdir], stderr=subprocess.STDOUT)
        if result.returncode != 0:
            log.exception(f'Retrieving ICs failed ... result: {result.returncode}')
            raise signals.FAIL()
    else:
        log.error("Unsupported forecast: ", ofs)
        raise signals.FAIL()

    return


#######################################################################


# job, dask
@task
def daskmake_mpegs(client: Client, job: Job, diff: bool=False):
    log.info(f"In daskmake_mpegs")

    # TODO: make the filespec a function parameter
    if not os.path.exists(job.OUTDIR):
        os.makedirs(job.OUTDIR)

    idx = 0
    futures = []

    plot_function = plot_shared.png_ffmpeg

    for var in job.VARS:
        # source = f"{job.OUTDIR}/ocean_his_%04d_{var}.png"

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
        #log.info(result)

    return


#######################################################################


# job, dask
@task
def daskmake_plots(client: Client, FILES: list, job: Job):
    target = job.OUTDIR

    log.info(f"In daskmake_plots {FILES}")

    log.info(f"Target is : {target}")
    if not os.path.exists(target):
        os.makedirs(target)

    idx = 0
    futures = []

    plot_function : callable 

    if job.OFS in util.roms_models:
      plot_function = plot_roms.plot
    elif job.OFS in util.fvcom_models:
      plot_function = plot_fvcom.plot


    # Submit all jobs to the dask scheduler
    # TODO - parameterize filespec and get files here?
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
        #log.info(result)

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
#####################################################################



@task
def daskmake_diff_plots(client: Client, EXPERIMENT: list, BASELINE: list, job: Job):
    ''' Create plots of baseline - experiment '''
    
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
    if job.OFS in util.roms_models:
      #plot_function = plot_roms.plot_diff
      plot_module = plot_roms
    elif job.OFS in util.fvcom_models:
      #plot_function = plot_fvcom.plot_diff
      plot_module = plot_fvcom

    baselen = len(BASELINE)
    explen  = len(EXPERIMENT)

    if baselen != explen:
        log.error(f"BASELINE and EXPERIMENT length mismatch: BASELINE {baselen}, EXPERIMENT {explen}" )
        raise signals.FAIL() 

    lastbase = BASELINE[baselen-1]
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
        #log.info(result)
    return
#####################################################################

