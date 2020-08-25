#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import sys
import os
import glob
from datetime import datetime

import boto3
import cmocean
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import matplotlib.pyplot as plt
import numpy as np
from xarray import open_mfdataset

from cloudflow.services.S3Storage import S3Storage
from cloudflow.job.Plotting import Plotting

DEBUG = True


# In[ ]:


def make_indexhtml(indexfile : str, imagelist : list):

    htmlhead = '''<html xmlns="http://www.w3.org/1999/xhtml">
                  <meta http-equiv="Cache-control" content="no-cache">
                  <head>
                  <title>Cloud-Sandbot</title>'''

    htmlbody = '<body>\n'
    for image in imagelist:
       imagehtml = f'<img src="{image}">\n'
       htmlbody += imagehtml

    htmlbody += '</body>\n'
    html = f'''{htmlhead}
               {htmlbody}
               </html>'''

    with open(indexfile, 'w') as index:
        index.write(html) 
        


# In[ ]:


def roms_nosofs(COMDIR: str, OFS: str, HH: str):
    """Load ROMS NOSOFS dataset"""

    filespec = f'{COMDIR}/nos.{OFS}.fields.f00*.t{HH}z.nc'
    print(f'filespec is: {filespec}')
    return open_mfdataset(filespec, decode_times=False, combine='by_coords')


# In[ ]:


def fvcom_nosofs(COMDIR: str, OFS: str, HH: str):
    """Load FVCOM NOSOFS dataset"""

    from netCDF4 import MFDataset

    filespec = f'{COMDIR}/nos.{OFS}.fields.f00*.t{HH}z.nc'
    print(f'filespec is: {filespec}')
    return MFDataset(filespec)


# In[ ]:


def dsofs_curr_fcst(COMROT: str='/com/nos'):
    """ Load the currently run OFS forecast on COMROT 
    This is almost the same as dosfs_newest, but will work better
    when running when injected in a workflow.
    It depends on a file being present in COMROT 'current.fcst'
    """
    
    cur_file = f'{COMROT}/current.fcst'
    with open(cur_file) as cf:
        fcst = cf.read().rstrip(' \n')
    
    print('fcst: ', fcst)
    
    COMDIR = f'{COMROT}/{fcst}'
    print('COMDIR: ', COMDIR)

    OFS = fcst.split('.')[0]
    fcstdate = fcst.split('.')[-1]
    HH = fcstdate[8:10]
    
    if DEBUG: # Only grab first 0-9 hours. Faster!
        filespec = f'{COMDIR}/nos.{OFS}.fields.f00*.t{HH}z.nc'
    else: # Grab all hours
        filespec = f'{COMDIR}/nos.{OFS}.fields.f*.t{HH}z.nc'
        
    print(f'filespec is: {filespec}')
    return open_mfdataset(filespec, decode_times=False, combine='by_coords')
    


# In[ ]:


# Testing
# dsofs_curr_fcst()


# In[ ]:


def plot_rho(ds, variable, s3upload=False) -> str:
    
    if variable == 'zeta':
        da = ds[variable].isel(ocean_time=0)
        cmap = cmocean.cm.phase
    if variable == 'temp':
        da = ds[variable].isel(ocean_time=0, s_rho=0)
        cmap = cmocean.cm.thermal
    if variable == 'salt':
        da = ds[variable].isel(ocean_time=0, s_rho=0)
        cmap = cmocean.cm.haline
    if variable == 'oxygen':
        da = ds[variable].isel(ocean_time=0, s_rho=0)
        cmap = cmocean.cm.oxy
    if variable == 'Pair':
        da = ds[variable].isel(ocean_time=0)
        cmap = cmocean.cm.diff
      
    fig = plt.figure(figsize=(12,5))
    ax = fig.add_axes([0,0,1,1], projection=ccrs.PlateCarree())
    im = ax.contourf(da.lon_rho, da.lat_rho, da.values,
                     transform=ccrs.PlateCarree(), 
                     cmap=cmap)
    
    coast_10m = cfeature.NaturalEarthFeature(
        'physical', 'land', '10m',
        edgecolor='k', facecolor='0.8'
    )
    ax.add_feature(coast_10m);
    
    title = ds.attrs['title']
    history = ds.history
    now = datetime.now().strftime("%m/%d/%Y, %H:%M:%S")
    print(now)
    ax.set_title(f"Image generated on {now}\n\n{title}\n{history}");
    
    cbar = fig.colorbar(im, ax=ax)
    long_name = da.attrs['long_name']
    if variable != 'salt':
        units = da.attrs['units']
        cbar.set_label(f'{long_name} ({units})')
    else:
        cbar.set_label(f'{long_name}')
    
    indexfile = f'docs/index.html'
    outfile = f'docs/{variable}.png'
    
    if not os.path.exists('./docs'):
        os.makedirs('./docs')

    imagename = outfile.split('/')[-1]

    plt.savefig(outfile, bbox_inches='tight')
             
    if s3upload:
        s3 = S3Storage()
        bucket = 'ioos-cloud-www'
        bucket_folder = 'sandbot/'
        bucket_folder = ''

        key = f'{bucket_folder}{variable}.png'
        s3.uploadFile(outfile, bucket, key, public = True)

    return imagename


# In[ ]:


def main():
       
    ds_ofs = dsofs_curr_fcst()
    
    indexfile = f'docs/index.html'
    if not os.path.exists('./docs'):
        os.makedirs('./docs')

    bucket = 'ioos-cloud-www'
    bucket_folder = ''
    #bucket_folder = 'sandbot/'

    
    storageService = S3Storage()

    rho_vars = ['temp',"zeta", "salt" ]

    imagelist = []

    for var in rho_vars:
        imagename = plot_rho(ds_ofs, var, s3upload=True)
        imagelist.append(imagename)

    make_indexhtml(indexfile, imagelist)
    storageService.uploadFile(indexfile, bucket, f'{bucket_folder}index.html', public=True, text=True)
    
    print('Finished ...')


# In[ ]:


main()

