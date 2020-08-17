#!/usr/bin/env python
# coding: utf-8

# # Cloud-Sandbot
# Bot that posts images from Cloud-Sandbox quasi-operational post-processing workflows. 
# 
# **Steps:**
# 1. Plot something using an example dataset
# 2. Upload output to s3
# 3. Convert the notebook to a script
# 4. Inject into cloudflow

# In[1]:

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


def make_indexhtml(indexfile : str, imagelist : list):

    htmlhead = '<html xmlns="http://www.w3.org/1999/xhtml">

            <head>
                <title>Cloud-Sandbot</title>
                <meta HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=utf-8">
                <meta name="Robots" content="NOINDEX " />
            </head>
            <script type="text/javascript">
                 var gearPage = document.getElementById('GearPage');
                 if(null != gearPage)
                 {
                     gearPage.parentNode.removeChild(gearPage);
                     document.title = "Error";
                 }
            </script>'

    htmlbody = '<body>'
    for image in imagelist:
       imagehtml = f'<img src=\'{image}\'>'
       htmlbody += imagehtml

    htmlbody += '</body>'
    html = '<html xmlns="http://www.w3.org/1999/xhtml">' + htmlhead + htmlbody + '</html>'

    with open(indexfile) as index:
        index.write(html) 


def roms_nosofs(COMDIR: str, OFS: str, HH: str):
    '''Load ROMS NOSOFS dataset'''

    # Should not use single leterr variable names
    # Choose a name that describes what it is
    filespec = f'{COMDIR}/nos.{OFS}.fields.f*.t{HH}z.nc'
    return open_mfdataset(filespec, decode_times=False, combine='by_coords')


def plot_rho(ds, variable, s3upload=False) -> imagename: str:
    
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
        s3 = cloudflow.services.S3Storage()
        bucket = 'ioos-cloud-www'
        s3.uploadFile(outfile, bucket, f'{variable}.png', public = True)

    return imagename


def main(argv):

    COMDIR = argv[1]
    OFS = argv[2]
    HH = argv[3]

    # could check that this is a roms model
    # if ofs in utils.roms_models then do roms
    # else if ofs in utils.fvcom_models then do fvcom

    ds_roms = roms_nosofs(COMDIR, OFS, HH)
    indexfile = f'docs/index.html'
    if not os.path.exists('./docs'):
        os.makedirs('./docs')

    bucket = 'ioos-cloud-www'

    storageService = cloudflow.services.S3Storage()

    rho_vars = ['temp']

    imagelist : list

    for var in rho_vars:
        imagename = plot_rho(ds_roms, var, s3upload=True)
        imagelist.append(imagename)

    make_indexhtml(indexfile, imagelist)
    storageService.uploadFile(indexfile, bucket, 'index.html', public = True, text = True)
    
if __name__ == '__main__':
    main(sys.argv)

