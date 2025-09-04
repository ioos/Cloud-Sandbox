import os
import urllib.request
from datetime import datetime
from datetime import timedelta

def getICsROMS(cdate, hh, ofs, comdir):

    #if len(locals()) != 4:
    #    print('Usage: {} YYYYMMDD HH cbofs|(other ROMS model) COMDIR'.format(os.path.basename(__file__)))
    #    exit()

    # url='https://nomads.ncep.noaa.gov/pub/data/nccf/com/nosofs/prod/{}.{}'.format(ofs,cdate)

    # Using NODD
    url = 'https://noaa-ofs-pds.s3.amazonaws.com/{}.{}'.format(ofs,cdate)

    if os.path.isdir(comdir):
        listCount = len(os.listdir(comdir))
        if listCount > 4:
            print('Looks like ICs already exist. .... skipping') 
            print('Remove the files in {} to re-download.'.format(comdir))
            return
    else:
        os.makedirs(comdir)

    os.chdir(comdir)

    pfx = '{}.t{}z.{}'.format(ofs,hh,cdate)
    sfx = 'nc'
    icfiles = [
      '{}.met.forecast.{}'.format(pfx,sfx),
      '{}.obc.{}'.format(pfx,sfx),
      '{}.river.{}'.format(pfx,sfx),
      '{}.roms.tides.{}'.format(pfx,sfx)
    ]
    # we make this one
    #   '{}.forecast.in'.format(pfx)
    
    print(f"icfiles: {icfiles}")

    for filename in icfiles:
        try:
            print('url: {}/{}'.format(url,filename))
            urllib.request.urlretrieve('{}/{}'.format(url,filename),filename)
        except:
            print('ERROR: Unable to retrieve {} from {}'.format(filename,url))
    
    # Need to rename the tides file - roms is still expecting basic name
    # os.rename('{}.roms.tides.{}'.format(pfx,sfx),'{}.roms.tides.nc'.format(ofs))
    # Fixed the above in nos_ofs_nowcast_forecast nosofs.v3.6.6

    if ofs == 'gomofs':
        climfile = '{}.clim.{}'.format(pfx,sfx)
        try:
            urllib.request.urlretrieve('{}/{}'.format(url,climfile),climfile)
        except:
            print('ERROR: Unable to retrieve {} from {}'.format(climfile, url))


    # Get the restart file: start from next cycle nowcast init
    # Get cdate cyc +6 hours init file, rename it to cdate cyc restart file
    datetimeObj = datetime.strptime(cdate+hh, '%Y%m%d%H')+timedelta(hours=6)
    next = datetimeObj.strftime('%Y%m%d%H')
    ncdate = list(next)[0:8]
    ncdate = ''.join(ncdate)
    print(ncdate)
    ncyc = list(next)[9:10]
    print(ncyc[0])

    npfx = '{}.t{:02d}z.{}'.format(ofs,int(ncyc[0]),ncdate)

    # OMG! The init.nowcast files are on NOMADS but NOT NODD
    # TODO: request these get added to the dump to NODD
    url='https://nomads.ncep.noaa.gov/pub/data/nccf/com/nosofs/prod/{}.{}'.format(ofs,cdate)
    if hh == str(18):
        url='https://nomads.ncep.noaa.gov/pub/data/nccf/com/nosofs/prod/{}.{}'.format(ofs,ncdate)

    ifile = '{}.init.nowcast.{}'.format(npfx,sfx)
    rfile = '{}.rst.nowcast.{}'.format(pfx,sfx)
    try:
        urllib.request.urlretrieve('{}/{}'.format(url,ifile),ifile)
    except:
        print('ERROR: Unable to retrieve {} from \n {}'.format(ifile,url))
    
    os.rename(ifile,rfile)
