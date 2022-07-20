import os
import urllib.request

def getICsFVCOM(ofs, cdate, hh, vdir):
    if len(locals()) < 3:
        print('Usage: {} cbofs|ngofs|etc. yyyymmdd hh [/com/nos-noaa/cbofs.20200416 | other destination]'.format(ofs))
        exit()
    
    if len(locals()) > 3:
        dest = vdir
    else:
        dest='{}.{}'.format(ofs,cdate)

    err = 0
    
    os.makedirs(dest)
    os.chdir(dest)

    
    