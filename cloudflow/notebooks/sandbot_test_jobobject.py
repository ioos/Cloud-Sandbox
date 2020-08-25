#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import sys
import os
import boto3
import cmocean
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from datetime import datetime
import matplotlib.pyplot as plt
import numpy as np
from xarray import open_mfdataset
from cloudflow.services.S3Storage import S3Storage
from cloudflow.job.Plotting import Plotting


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
    '''Load ROMS NOSOFS dataset'''

    # Why load in the entire dataset when only plotting one time slice? 
    # It is extremely slow!
    #  nos.gomofs.fields.f006.20200819.t00z.nc
    filespec = f'{COMDIR}/nos.{OFS}.fields.f00*.t{HH}z.nc'
    print(f'filespec is: {filespec}')
    return open_mfdataset(filespec, decode_times=False, combine='by_coords')


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
        s3.uploadFile(outfile, bucket, f'{variable}.png', public = True)

    return imagename


# In[ ]:


def main(job: Plotting):

    COMDIR = job.INDIR
    OFS = job.OFS
    HH = job.HH
    rho_vars = job.VARS

    print(f'COMDIR is: {COMDIR}')
    print(f'OFS is: {OFS}')
    print(f'HH is: {HH}')
    print('Running ...')

    # could check that this is a roms model
    # if ofs in utils.roms_models then do roms
    # else if ofs in utils.fvcom_models then do fvcom

    ds_roms = roms_nosofs(COMDIR, OFS, HH)
    indexfile = f'docs/index.html'
    if not os.path.exists('./docs'):
        os.makedirs('./docs')

    bucket = 'ioos-cloud-www'

    storageService = S3Storage()

    #rho_vars = ['temp',"zeta", "salt" ]

    imagelist = []

    for var in rho_vars:
        imagename = plot_rho(ds_roms, var, s3upload=True)
        imagelist.append(imagename)

    make_indexhtml(indexfile, imagelist)
    storageService.uploadFile(indexfile, bucket, 'index.html', public=True, text=True)
    
    print('Finished ...')
    # return ds_roms
    


# In[ ]:


''' We're still looking for a way to not have to do something like this.
We really want this job to run without having to specify any parameters.
'''
jobfile = 'plotting_job.json'
NPROCS = 1
testjob = Plotting(jobfile, 1)
main(testjob)

