import os
import urllib.request
from datetime import datetime
from datetime import timedelta

def getICsROMS(cdate, hh, ofs, comdir):

    if len(locals()) != 4:
        print('Usage: {} YYYYMMDD HH cbofs|(other ROMS model) COMDIR'.format(os.path.basename(__file__)))
        exit()

    url='https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/{}.{}'.format(ofs,cdate)

    if os.path.isdir(comdir):
        listCount = len(os.listdir(comdir))
        if listCount > 4:
            print('Looks like ICs already exist. .... skipping') 
            print('Remove the files in {} to re-download.'.format(comdir))
            exit()
    else:
        os.makedirs(comdir)
    os.chdir(comdir)

    pfx = 'nos.{}'.format(ofs)
    sfx = '{}.t{}z.nc'.format(cdate,hh)
    icfiles = ['{}.met.forecast.{}'.format(pfx,sfx),
    '{}.obc.{}'.format(pfx,sfx),
    '{}.river.{}'.format(pfx,sfx),
    '{}.roms.tides.{}'.format(pfx,sfx),
    '{}.forecast.{}.t{}z.in'.format(pfx,cdate,hh)]
    
    print(icfiles)

    for file in icfiles:
        try:
            urllib.request.urlretrieve('{}/{}'.format(url,file),file)
        except:
            print('ERROR: Unable to retrieve {} from {}'.format(file,url))
            exit()
    
    # Need to rename the tides file - roms is still using generic name
    os.rename('{}.roms.tides.{}'.format(pfx,sfx),'nos.{}.roms.tides.nc'.format(ofs))

    if ofs == 'gomofs':
        climfile = '{}.clim.{}'.format(pfx,sfx)
        try:
            urllib.request.urlretrieve('{}/{}'.format(url,climfile),climfile)
        except:
            print('ERROR: Unable to retrieve {} from {}'.format(climfile, url))
            exit()

    # Get cdate cyc +6 hours init file, rename it to cdate cyc restart file
    datetimeObj = datetime.strptime(cdate+hh, '%Y%m%d%H')+timedelta(hours=6)
    next = datetimeObj.strftime('%Y%m%d%H')
    ncdate = list(next)[0:8]
    ncdate = ''.join(ncdate)
    print(ncdate)
    ncyc = list(next)[9:10]
    print(ncyc[0])

    nsfx = '{}.t{:02d}z.nc'.format(ncdate,int(ncyc[0]))

    if hh == str(18):
        url = 'https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/{}.{}'.format(ofs,ncdate)
    
    ifile = '{}.init.nowcast.{}'.format(pfx,nsfx)
    rfile = '{}.rst.nowcast.{}'.format(pfx,sfx)
    try:
        urllib.request.urlretrieve('{}/{}'.format(url,ifile),ifile)
    except:
        print('ERROR: Unable to retrieve {} from \n {}'.format(ifile,url))
        exit()
    
    os.rename(ifile,rfile)