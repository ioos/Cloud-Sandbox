import os
import urllib.request

def getNomadsProd(ofs, cdate, cyc, vdir):
    if len(locals()) < 3:
        print('Usage: {} cbofs|ngofs|etc. yyyymmdd hh [/com/nos-noaa/cbofs.20200416 | other destination]'.format(ofs))
        exit()
    
    if len(locals()) > 3:
        dest = vdir
    else:
        dest = '{}.{}'.format(ofs,cdate)

    err = 0
    os.makedirs(dest)
    os.chdir(dest)

    nomads='https://nomads.ncep.noaa.gov/pub/data/nccf/com/nos/prod/{}.{}'.format(ofs,cdate)

    # Download every hour forecast
    ###############################################################
    # Forecasts don't follow the same pattern, some don't have f000, some are 3 hourly (gomofs)
    hlist=['00','01','02','03','04','05','06','07','08','09']

    # Most forecasts are 48 hours, with some exceptions
    ehr=48
    if ofs == 'gomofs':
        ehr = 72
    elif ofs == 'ngofs':
        ehr = 54
    elif ofs == 'leofs' or ofs == 'lmhofs':
        ehr = 120

    for hh in hlist:
        hhFile = 'nos.{}.fields.f0{}.{}.t{}z.nc'.format(ofs,hh,cdate,cyc)
        try:
            urllib.request.urlretrieve('{}/{}'.format(nomads,hhFile),hhFile)
        except:
            print('ERROR: Unable to retrieve {} from \n {}'.format(hhFile,nomads))
            continue

    hh = 10
    while hh <= ehr:
        if hh < 100:
            hhstr = '0{}'.format(hh)
        else:
            hhstr = str(hh)
        file = 'nos.{}.fields.f{}.{}.t{}z.nc'.format(ofs,hhstr,cdate,cyc)
        try:
            urllib.request.urlretrieve('{}/{}'.format(nomads,file),file)
        except:
            print('ERROR: Unable to retrieve {} from \n {}'.format(file,nomads))
            hh+=1
            continue
        hh+=1
    ###############################################################

    # Get the nestnode files if ngofs 
    # No longer necessary for Ngofs2??

    #if ofs == 'ngofs':
    #    file1 = 'nos.{}.obc.{}.t{}z.nc'.format(ofs,cdate,cyc)
    #    try:
    #        urllib.request.urlretrieve('{}/{}'.format(nomads,file1))
    #    except:
    #        exit()

    #   os.rename(file1, 'nos.{}.nestnode.forecast.{}.t{}z.nc'.format(ofs,cdate,cyc))
    #    
    #    file2 = 'nos.{}.obc.{}.t{}z.nc'.format(ofs,cdate,cyc)
    #    try:
    #        urllib.request.urlretrieve('{}/{}'.format(nomads,file2))
    #    except:
    #        exit()

    # Get the log and .in config files
    inFile = 'nos.{}.forecast.{}.t{}z.in'.format(ofs,cdate,cyc)
    logFile = 'nos.{}.forecast.{}.t{}z.log'.format(ofs,cdate,cyc)
    try:
        urllib.request.urlretrieve('{}/{}'.format(nomads,inFile),inFile)
    except:
        print('ERROR: Unable to retrieve {} from \n {}'.format(inFile,nomads))
        exit()
    try:
        urllib.request.urlretrieve('{}/{}'.format(nomads,logFile),logFile)
    except:
        print('ERROR: Unable to retrieve {} from \n {}'.format(logFile,nomads))
        exit()
