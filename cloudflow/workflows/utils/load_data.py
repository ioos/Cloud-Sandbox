#!/usr/bin/python

def roms():
    '''Load ROMS example dataset'''
    from xarray import open_mfdataset
    f = '/com/nos/dbofs.2020072300/nos.dbofs.fields.f*.t00z.nc'
    return open_mfdataset(f, decode_times=False, combine='by_coords')

def fvcom():
    '''Load FVCOM example dataset'''
    from netCDF4 import MFDataset
    f = '/data/example_datasets/negofs.20200605/nos.negofs.fields.f*t03z.nc'
    return MFDataset(f)