import os
import urllib.request
from datetime import datetime
from datetime import timedelta

from cloudflow.utils import modelUtil as util

NOMADS = 'https://nomads.ncep.noaa.gov/pub/data/nccf/com/nosofs/prod'
NODD   = 'https://noaa-ofs-pds.s3.amazonaws.com'

# TODO: Refactor this, too much duplicate code

def getICs(cdate, hh, ofs, comdir):

    errors=0

    #if len(locals()) != 4:
    #    print('Usage: {} YYYYMMDD HH cbofs|(other ROMS model) COMDIR'.format(os.path.basename(__file__)))
    #    exit()

    if os.path.isdir(comdir):
        listCount = len(os.listdir(comdir))

        # Below only works if COMDIR is unique to this run, ops puts 4 cycles in one folder 
        # TODO: refactor to be specific to actual ic files, files are relatively small for these
        #       redownloading from NODD not really an issue
        #
        #if listCount > 4:
        #    print('Looks like ICs already exist. .... skipping') 
        #    print('Remove the files in {} to re-download.'.format(comdir))
        #    return
    else:
        os.makedirs(comdir)

    os.chdir(comdir)

    pfx = '{}.t{}z.{}'.format(ofs,hh,cdate)
    sfx = 'nc'

    if ofs in util.nosofs_roms_models:
      icfiles = [
        '{}.met.forecast.{}'.format(pfx,sfx),
        '{}.obc.{}'.format(pfx,sfx),
        '{}.river.{}'.format(pfx,sfx),
        '{}.roms.tides.{}'.format(pfx,sfx) ]
      on_nomads = []

    # loofs and lsofs do not have obc 
    elif ofs in util.nosofs_fvcom_models:
      # no river.nc.tar on NODD ugh!!!
      # leofs.t00z.20250916.river.nc.tar  

      # loofs and lsofs have no obc file
      if ofs in "loofs lsofs":
        icfiles = [
          '{}.met.forecast.{}'.format(pfx,sfx),
          '{}.hflux.forecast.{}'.format(pfx,sfx) ]
      else:
        icfiles = [
          '{}.met.forecast.{}'.format(pfx,sfx),
          '{}.obc.{}'.format(pfx,sfx),
          '{}.hflux.forecast.{}'.format(pfx,sfx) ]
      # no river.nc.tar on NODD ugh!!!
      # leofs.t00z.20250916.river.nc.tar  
      on_nomads = [ '{}.river.{}.tar'.format(pfx,sfx) ]

    else:
      print(f"WARNING: Don't know how to get ICs for {ofs}") 
    
    url = '{}/{}.{}'.format(NODD,ofs,cdate)
    for filename in icfiles:
        try:
            print('url: {}/{}'.format(url,filename))
            urllib.request.urlretrieve('{}/{}'.format(url,filename),filename)
        except:
            print('ERROR: Unable to retrieve {} from {}'.format(filename,url))
            errors += 1

    if ofs in ['gomofs','wcofs']:
        climfile = '{}.clim.{}'.format(pfx,sfx)
        try:
            urllib.request.urlretrieve('{}/{}'.format(url,climfile),climfile)
        except:
            print('ERROR: Unable to retrieve {} from {}'.format(climfile, url))
            errors += 1

    url = '{}/{}.{}'.format(NOMADS,ofs,cdate)
    for filename in on_nomads:
        try:
            print('url: {}/{}'.format(url,filename))
            urllib.request.urlretrieve('{}/{}'.format(url,filename),filename)
        except:
            print('ERROR: Unable to retrieve {} from {}'.format(filename,url))
            errors += 1

    #####################################
    # restart init file
    #####################################
    # Get the restart file: start from next cycle nowcast init
    # Get cdate cyc +6 hours init file, rename it to cdate cyc restart file
    nextdate = datetime.strptime(cdate+hh, '%Y%m%d%H')+timedelta(hours=6)
    nextday = datetime.strptime(cdate+hh, '%Y%m%d%H')+timedelta(hours=24)

    # next cdate and cyc
    ncdate = nextdate.strftime('%Y%m%d')
    ncyc = nextdate.strftime('%H')
    npfx = '{}.t{}z.{}'.format(ofs,ncyc,ncdate)

    #print(f"ncdate: {ncdate}")
    #print(f"ncyc: {ncyc}")
    #print(f"npfx: {npfx}")

    # The init.nowcast files are on NOMADS, NOT on NODD
    # TODO?: request these get added to the dump to NODD
    url='{}/{}.{}'.format(NOMADS,ofs,cdate)

    #TODO: Double check the TIDE REFERENCE and init restart file TIMES match those in operational runs
    if ofs == 'wcofs':
        # wcofs runs only once per day, different folder
        ncdate = nextday.strftime('%Y%m%d')
        ncyc = nextday.strftime('%H')
        npfx = '{}.t{}z.{}'.format(ofs,ncyc,ncdate) 
        url='{}/{}.{}'.format(NOMADS,ofs,ncdate)
    
    if hh == str(18):
        # next cycle will be in next day's folder if current cyc = 18
        url='{}/{}.{}'.format(NOMADS,ofs,ncdate)

    # Download init.nowcast and rename to rst.nowcast 
    ifile = '{}.init.nowcast.{}'.format(npfx,sfx)
    rfile = '{}.rst.nowcast.{}'.format(pfx,sfx)
    try:
        urllib.request.urlretrieve('{}/{}'.format(url,ifile),rfile)
    except:
        print('ERROR: Unable to retrieve {} from \n {}'.format(ifile,url))
        errors += 1

    if errors != 0:
        raise Exception(f"Problems encountered downloading forcing, initial conditions, for {ofs} {cdate}")
