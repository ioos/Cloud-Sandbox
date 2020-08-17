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
import boto3
import cmocean
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from datetime import datetime
import matplotlib.pyplot as plt
import numpy as np
from xarray import open_mfdataset


def roms_nosofs(COMDIR: str, OFS: str, HH: str):
    '''Load ROMS NOSOFS dataset'''

    # Should not use single leterr variable names
    # Choose a name that describes what it is
    filespec = f'{COMDIR}/nos.{OFS}.fields.f*.t{HH}z.nc'
    return open_mfdataset(filespec, decode_times=False, combine='by_coords')


def upload_to_s3(file, key, ExtraArgs):
    bucket = 'ioos-cloud-www'
    session = boto3.Session()
    client = session.client('s3')
    client.upload_file(file, bucket, key, ExtraArgs)


def plot_rho(ds, variable, s3upload=False):
    
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
    plt.savefig(outfile, bbox_inches='tight')
                 
    if s3upload:
        upload_to_s3(indexfile, 'index.html', 
                     ExtraArgs={
                         'ACL': 'public-read',
                         'ContentType':'text/html'
                     })
        upload_to_s3(outfile, f'{variable}.png',
                     ExtraArgs={
                         'ACL': 'public-read'
                     })


def main(argv):

    COMDIR = argv[1]
    OFS = argv[2]
    HH = argv[3]

    # could check that this is a roms model
    # if ofs in utils.roms_models then do roms
    # else if ofs in utils.fvcom_models then do fvcom

    ds_roms = roms_nosofs(COMDIR, OFS, HH)

    rho_vars = ['temp']

    # Bad practice to use single letter variable names. They are extremely difficult to search for.
    for var in rho_vars:
        plot_rho(ds_roms, var, s3upload=True)


if __name__ == '__main__':
    main(sys.argv)

