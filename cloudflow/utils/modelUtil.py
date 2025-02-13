""" Various routines, not just for ROMS models anymore.
TODO: Rename this module.
"""
import datetime
import json
import math
import os
import re
import subprocess

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False

roms_models = ["adnoc","cbofs","ciofs","dbofs","gomofs","liveocean","tbofs"]
fvcom_models = ["leofs", "lmhofs", "negofs", "ngofs", "nwgofs", "sfbofs", "ngofs2"]

nosofs_models = [ "cbofs","ciofs","dbofs","gomofs","tbofs",
                  "leofs", "lmhofs", "negofs", "ngofs", "nwgofs", "sfbofs", "ngofs2"]

def nosofs_cyc0(ofs : str) -> str:
    if ofs in [ "negofs", "ngofs", "nwgofs", "sfbofs", "ngofs2" ]:
        return "03"
    else:
        return "00"


def scrub_liveocean():
    """ scrubs the disk - removes forcings/ICs and forecast data
        older than x days """

    # This is done in a shell script called by cron

    # Scrub plots older than 1 day - these have been sent to S3
    # Scrub forcing older than 1 day - can redownload from UW
    # Scrub foreast data
    #   Older than 1 day - remove all except hour 01-25
    #   Older than 1 week - remove all
    #

    print('scrub_liveocean stub')
    return


#####################################################################


def readConfig(configfile):
    """ converts a JSON document to a python dictionary """

    if debug: print(f"DEBUG: in modelUtil : configfile is: {configfile}")

    with open(configfile, 'r') as cf:
        cfDict = json.load(cf)

    if (debug):
        print(json.dumps(cfDict, indent=4))
        print(str(cfDict))

    return cfDict


#####################################################################


def sedoceanin(template, outfile, settings):
    """ substitues the templated fields with specified settings, like sed """
    with open(template, 'r') as infile:
        lines = infile.readlines()

    with open(outfile, 'w') as outfile:
        for line in lines:
            newline = line

            for key, value in settings.items():
                newline = re.sub(key, str(value), newline)

            outfile.write(re.sub(key, value, newline))
    return


#####################################################################


def makeOceanin(NPROCS, settings, template, outfile, ratio=1.0):
    """ creates the ocean.in file for ROMS forecasts using templated variables """

    tiles = getTiling(NPROCS, ratio)

    reptiles = {
        "__NTILEI__": str(tiles["NtileI"]),
        "__NTILEJ__": str(tiles["NtileJ"]),
    }

    settings.update(reptiles)
    sedoceanin(template, outfile, settings)
    return

#####################################################################



def ndays(cdate1, cdate2):
    """ Calculate the number of days between two dates

    """
    dt = datetime.timedelta(days=0)

    y1 = int(cdate1[0:4])
    m1 = int(cdate1[4:6].lstrip("0"))
    d1 = int(cdate1[6:8].lstrip("0"))

    y2 = int(cdate2[0:4])
    m2 = int(cdate2[4:6].lstrip("0"))
    d2 = int(cdate2[6:8].lstrip("0"))

    # extended to include optional hours

    if len(cdate1) == 10:
        hh = cdate1[8:10]
        if hh == '00':
            h1 = 0
        else:
            h1 = int(cdate1[8:10].lstrip("0"))
    else:
        h1 = 0

    if len(cdate2) == 10:
        hh = cdate2[8:10]
        if hh == '00':
            h2 = 0
        else:
            h2 = int(cdate2[8:10].lstrip("0"))
    else:
        h2 = 0

    date1 = datetime.datetime(y1, m1, d1, h1)
    date2 = datetime.datetime(y2, m2, d2, h2)
    dt = date1 - date2

    days = dt.days

    hour = dt.seconds / 3600
    daysdec = hour / 24
    days = days + daysdec

    return str(days)


#####################################################################


def ndate_hrs(cdate :str, hours :int):
    """ return the YYYYMMDDHH for CDATE +/- hours """

    y1 = int(cdate[0:4])
    m1 = int(cdate[4:6].lstrip("0"))
    d1 = int(cdate[6:8].lstrip("0"))

    hh = cdate[8:10]
    if hh == '00':
        h1 = 0
    else:
        h1 = int(cdate[8:10].lstrip("0"))

    dt = datetime.timedelta(hours=hours)

    date2 = datetime.datetime(y1, m1, d1, h1) + dt
    strdate = date2.strftime("%Y%m%d%H")

    return strdate


#####################################################################


def ndate(cdate, days):
    """ return the YYYYMMDD for CDATE +/- days """

    y1 = int(cdate[0:4])
    m1 = int(cdate[4:6].lstrip("0"))
    d1 = int(cdate[6:8].lstrip("0"))

    dt = datetime.timedelta(days=days)

    date2 = datetime.date(y1, m1, d1) + dt
    strdate = date2.strftime("%Y%m%d")
    return strdate


#####################################################################


def lo_date(cdate):
    """ return the LiveOcean format of date e.g. f2019.11.06"""

    fdate = f"f{cdate[0:4]}.{cdate[4:6]}.{cdate[6:8]}"

    return fdate


#####################################################################


def getTiling(totalCores, ratio=1.0):
    """ Determines the ROMS tiling to use based on the number of cores available.
    Sets NtileI and NtileJ

    Parameters
    ----------
    totalCores : int
        The number of cores to use

    ratio : float
        The approximate aspect ratio of the model grid, I/J
    """

    '''
    Basic algorithm.
    prefer a square or closest to it.
    if sqrt of total is an integer then use it for I and J.
    if not, find factorization closest to square.

    36 = sqrt(36) = ceil(6)  36 mod 6 = 0 - DONE
    NtileI=6, NtileJ=6
    32 = sqrt(32) = 5.65 32
    mod 6 != 0
    mod 5 != 0
    mod 4 == 0
    32 / 4 = 8 - DONE
    NtileI=8, NtileJ=4

    It might be more optimal to have a ratio similar to the grid ratio.
    '''

    NtileI = 1
    NtileJ = 1

    # totalCores = coresPN * nodeCount
    if debug:
        print('In getTiling: totalCores = ', str(totalCores))

    if ((totalCores != 1) and (totalCores % 2 != 0)):
        raise Exception("Total cores must be even")
    if ratio == 0:
        raise Exception("Ratio must not equal 0")

    # Try to balance NtileI and NtileJ
    # system of equations
    # NtileJ = NtileI / ratio
    # NtileI = NtileJ * ratio
    # NPROCS = totalCores
    # NPROCS = NtileI * NtileJ
    # NPROCS = (NtileJ**2) * ratio
    # NtileJ**2 = totalCores/ratio
    # NtileJ = math.ceil(math.sqrt(totalCores/ratio))
    # NtileI = int(totalCores/NtileJ)

    done = "false"
    square = math.sqrt(totalCores / ratio)
    ceil = math.ceil(square)

    # Find a value that uses all available cores
    while (done == "false"):
        if ((totalCores % ceil) == 0):
            NtileJ = ceil
            NtileI = int(totalCores / NtileJ)
            done = "true"
        else:
            ceil -= 1

    print("NtileI : ", NtileI, " NtileJ ", NtileJ)

    if debug:
        print(f"DEBUG: totalCores: {totalCores} I*J: {NtileI * NtileJ} ratio: {ratio} I/J: {NtileI / NtileJ}")

    return {"NtileI": NtileI, "NtileJ": NtileJ}


#####################################################################


def get_ICs_roms(ofs, cdate, cycle, localpath):
    # There is a shell script that already exists to do this
    # Can maybe re write it in Python later
    # Or wrap it here
    return


def get_baseline_lo(cdate, vdir, sshuser):
    """ Retrieve operational LiveOcean forecast data from UW """

    remotepath = "/data1/parker/LiveOcean_roms/output/cas6_v3_lo8b"
    fdate = lo_date(cdate)

    if os.path.exists(vdir):
        if len(os.listdir(vdir)) != 0:
            print(f"Baselines seem to already exist in  {vdir} ... not downloading.")
            print(f"Remove the {vdir} directory to force the download.")
            return
        else:
            # We will scp the entire path from UW so delete existing directory
            os.rmdir(vdir)

    # Get the forcing
    scpdir = f"{sshuser}:{remotepath}/{fdate}"

    # TODO: add exception handing, check return value from scp
    # Python can not escape the \* as desired, so we have to scp -rp
    # could probably use shell=True style instead

    # Remove the trailing path specifier from vdir
    vpath = '/'.join(vdir.split('/')[0:-1])

    result = subprocess.run(["scp", "-rp", scpdir, vpath], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if result != 0:
        print("Error retrieving liveocean baselines: ", result.stdout)

    return

def get_ICs_lo_cas7_hindcast(cdate, localpath, sshuser):
    """ Get the atmospheric forcing and boundary layer conditions and ICs
        for LiveOcean ROMS model.

        This requires an account on the remote server with private key authentication.
    """

    # Not using Parker's restart, but our own from previous day
    #restart_file = "ocean_his_0025.nc"
    #remotepath_rst = "/data1/parker/LiveOcean_roms/output/cas6_v3_lo8b"

    remotepath = "/dat1/parker/LO_output/forcing/cas7"

    fdate = lo_date(cdate)
    prevdate = ndate(cdate, -1)
    fprevdate = lo_date(prevdate)

    forceroot = localpath
    forcedir = f"{localpath}/{fdate}"

    if not os.path.exists(forcedir):
        os.makedirs(forcedir)
    else:
        # TODO: check if empty
        print(f"Forcing directory {forcedir} already exists .... not downloading.")
        print(f"Remove the {forcedir} directory to force the download.")
        return

    # Get the forcing
    scpdir = f"{sshuser}:{remotepath}/{fdate}"

    # TODO: add exception handing, check return value from scp
    subprocess.run(["scp", "-rp", scpdir, forceroot], stderr=subprocess.STDOUT)



def get_ICs_lo(cdate, localpath, sshuser):

    """ Out of date """
    print("get_ICs_lo needs an update... skipping")
    return

    """ Get the atmospheric forcing and boundary layer conditions and ICs
        for LiveOcean ROMS model.

        This requires an account on the remote server with private key authentication.
    """

    restart_file = "ocean_his_0025.nc"
    remotepath = "/data1/parker/LiveOcean_output/cas6_v3"
    remotepath_rst = "/data1/parker/LiveOcean_roms/output/cas6_v3_lo8b"

    fdate = lo_date(cdate)
    prevdate = ndate(cdate, -1)
    fprevdate = lo_date(prevdate)

    forceroot = f"{localpath}/forcing"
    forcedir = f"{forceroot}/{fdate}"

    if not os.path.exists(forcedir):
        os.makedirs(forcedir)
    else:

        # TODO: check if empty
        print(f"Forcing directory {forcedir} already exists .... not downloading.")
        print(f"Remove the {forcedir} directory to force the download.")
        return

    # Get the forcing
    scpdir = f"{sshuser}:{remotepath}/{fdate}"

    # TODO: add exception handing, check return value from scp
    subprocess.run(["scp", "-rp", scpdir, forceroot], stderr=subprocess.STDOUT)

    # Instead of hardcoding path, create a symlink
    # SSFNAME == /com/liveocean/forcing/f2019.11.06/riv2/rivers.nc
    # SSFNAME == rivers.nc
    # ln -s {forcedir}/{fdate}/riv2/rivers.nc {localpath}/{fdate}/rivers.nc
    #subprocess.run(["ln", "-s", f"{forcedir}/riv2/rivers.nc", \
                    #f"{localpath}/{fdate}/rivers.nc"], stderr=subprocess.STDOUT)

    # TODO - add error checking and return code
    subprocess.run(["cp", "-pf", f"{forcedir}/riv2/rivers.nc", \
                    f"{localpath}/{fdate}/rivers.nc"], stderr=subprocess.STDOUT)

    # Get the restart file from the previous day's forecast
    scpdir = f"{sshuser}:{remotepath_rst}/{fprevdate}"
    localdir = f"{localpath}/{fprevdate}"

    if not os.path.exists(localdir):
        os.mkdir(localdir)

    subprocess.run(["scp", "-p", f"{scpdir}/{restart_file}", localdir], stderr=subprocess.STDOUT)

    return


#####################################################################

if __name__ == '__main__':
    pass
