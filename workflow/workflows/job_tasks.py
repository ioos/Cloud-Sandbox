"""
"""
# Python dependencies
import logging
import subprocess
import sys
import os
import glob
from distributed import Client
from prefect.engine import signals
from prefect import task

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))
curdir = os.path.dirname(os.path.abspath(__file__))

from job.Job import Job

from plotting import plot_roms
from plotting import plot_fvcom

import utils.romsUtil as util

__copyright__ = "Copyright © 2020 RPS Group. All rights reserved."
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

# job
# TODO: make sshuser an optional Job parameter
# TODO: make this model agnostic
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
        script = f"{curdir}/../../scripts/getICsROMS.sh"

        result = subprocess.run([script, cdate, hh, ofs, comdir], stderr=subprocess.STDOUT)
        if result.returncode != 0:
            log.exception(f'Retrieving ICs failed ... result: {result.returncode}')
            raise signals.FAIL()

    # FVCOM models
    elif ofs in ('ngofs', 'nwgofs', 'negofs', 'leofs', 'sfbofs', 'lmhofs'):
        comdir = f"{comrot}/{ofs}.{cdate}"
        script = f"{curdir}/../../scripts/getICsFVCOM.sh"

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
def daskmake_mpegs(client: Client, job: Job):
    log.info(f"In daskmake_mpegs")

    # TODO: make the filespec a function parameter
    if not os.path.exists(job.OUTDIR):
        os.makedirs(job.OUTDIR)

    idx = 0
    futures = []


    if job.OFS in util.roms_models:
      plot_function = plot_roms.png_ffmpeg
    elif job.OFS in util.fvcom_models:
      plot_function = plot_fvcom.png_ffmpeg

    for var in job.VARS:
        # source = f"{job.OUTDIR}/ocean_his_%04d_{var}.png"
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
