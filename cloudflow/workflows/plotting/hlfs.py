#!/usr/bin/env python
# coding: utf-8

# # Research to Operations
# ### Preparing the notebook for workflow injection
# 
# Requirements:
# 
# * No user supplied module dependencies. 3rd party libraries/modules are fine and expected.
# * All input/output paths specified in config file.

# In[1]:


def main(fp):
    '''Plot a contour map showing the spatially explicit times of the 
    next low tide elevation for ROMS model output.
    
    :param str fp: File path for config file
    '''
    import json
    import datetime

    import boto3
    import cartopy.crs as ccrs
    import cartopy.feature as cfeature
    import cmocean
    import matplotlib.pyplot as plt
    import numpy as np
    import pandas as pd
    import scipy.spatial
    import xarray as xr

    with open(fp, 'rb') as f:
        config = json.load(f)

    if config['CDATE'] == 'today':
        CDATE = datetime.date.today().strftime("%Y%m%d")
    else:
        CDATE = config['CDATE']

    OFS = config['OFS']
    fspec = config['FSPEC']

    indir = f"{config['INDIR']}/{OFS}.{CDATE}"
    outdir = f"{config['OUTDIR']}"
    ds = xr.open_mfdataset(f'{indir}/{fspec}', decode_times=False, combine='by_coords')


    def convert_time(t):
        '''convert roms ocean_time to pd.Timestamp()'''
        timestr = ds.ocean_time.units.split(' ')[-2:]
        return pd.Timestamp(str(' ').join(timestr)) + pd.Timedelta(seconds=int(t))


    # Extract time and transform to human pandas Timestamp format
    ocean_time = ds.ocean_time.values
    human_time = list(map(convert_time, ocean_time.astype(int)))

    # Set time interval for tidal day and create slice
    interval = pd.Timedelta('12.5H')
    start = human_time[0]
    end = start + interval
    idx = [i for i, t in enumerate(human_time) if (t >= start) & (t <= end)]
    ot_slice = slice(ocean_time[min(idx)], ocean_time[max(idx)])
    ht_slice = slice(human_time[min(idx)], human_time[max(idx)])

    # DataArray for the tidal day; and index, values and times for min zeta
    ds_td = ds.zeta.sel(ocean_time=ot_slice)
    zmin_idx = ds_td.values.argmin(axis=0)
    zmin_val = ds_td.values.min(axis=0)
    zmin_times = xr.DataArray(
        np.array(
            [ocean_time[i] for i in zmin_idx.flatten()]
        ).reshape(zmin_idx.shape),
        dims = ('eta_rho', 'xi_rho')
    ).where(~np.isnan(zmin_val))

    # Dataset for plotting spatial model data
    ds_hlfs = xr.Dataset({
            'zmin_val': (('eta_rho', 'xi_rho'), zmin_val),
            'zmin_time': zmin_times
        },
        coords={
            'lon_rho': (('eta_rho', 'xi_rho'), ds.lon_rho.values),
            'lat_rho': (('eta_rho', 'xi_rho'), ds.lat_rho.values)
        }
    )
    
    # Spatial: time of low tide
    proj = ccrs.LambertConformal(central_longitude=-76, central_latitude=38)
    fig2 = plt.figure(
        figsize=(12,5)
    )
    ax2 = plt.axes(projection=proj)
    field = ds_hlfs.zmin_time.plot(
        x='lon_rho', y='lat_rho',
        transform=ccrs.PlateCarree(),
        cmap=cmocean.cm.phase,
        add_colorbar=False,
        add_labels=False
    )
    ax_cbar = fig2.add_axes()
    cbar = fig2.colorbar(field, cax=ax_cbar)
    cbar.set_ticks(cbar.get_ticks())
    cbar.set_ticklabels(
        [convert_time(i).strftime('%H:%M:%S') for i in cbar.get_ticks()]
    )
    ax2.set_title(f'CBOFS: Time of next low tide\n{ds.history}');
    coast_10m = cfeature.NaturalEarthFeature(
        'physical', 'land', '10m',
        edgecolor='k', facecolor='0.8'
    )
    ax2.add_feature(coast_10m);
    
    ############# Output #############
    # Save to user output folder
    outfile = f'{OFS}-{CDATE}-hlfs.png'
    plt.savefig(f'{outdir}/{outfile}')

    # Save the file to S3
    s3 = boto3.client('s3')
    bucket = config['BUCKET']
    key = config['BCKTFLDR'] + '/' + outfile
    try:
        s3.upload_file(f'{outdir}/{outfile}', bucket, key, ExtraArgs={'ACL': 'public-read'})
    except ClientError as e:
        raise Exception from e


# In[ ]:


fp = 'hlfs.config'
main(fp)


# In[ ]:




