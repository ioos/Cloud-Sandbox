
import matplotlib
matplotlib.use('Agg')

import datetime
import itertools
import matplotlib.pyplot as plt
import netCDF4
import numpy as np
import os
import pandas as pd
import PIL.Image
import pyproj
import sys

import tile

EPSG3857 = pyproj.Proj(init='EPSG:3857')
TILE3857 = tile.Tile3857()

def plot(ncpath, t, ZOOM=8, crop=True):

    with netCDF4.Dataset(ncpath) as nc:

        nv = nc.variables['nv'][:].T
        nv = nv - 1

        # lon/lat nodes
        lon = nc.variables['lon'][:]
        lon = np.where(lon > 180., lon-360., lon)
        lat = nc.variables['lat'][:]

        # lon/lat cell centers
        lonc = nc.variables['lonc'][:]
        lonc = np.where(lonc > 180., lonc-360., lonc)
        latc = nc.variables['latc'][:]

        # project to EPSG:3857 for map
        lo,la   = EPSG3857(lon,lat)
        loc,lac = EPSG3857(lonc,latc)

        # get variable of interest here
        # 3D variable
        #u = nc.variables['u'][t,0,:]  # sfc is first vertical level
        #v = nc.variables['v'][t,0,:]
        # temp(time, siglay, node)
        temp = nc.variables['temp'][t,0,:]

        # 2D (surface) variable
        zeta = nc.variables['zeta'][t,:]


        # render bounds, draw entire tiles in EPSG:3857
        ulll = ( # upper left  longitude, latitude
            min(lo.min(), loc.min()), # west
            max(la.max(), lac.max())  # north
        )
        urll = ( # upper right longitude, latitude
            max(lo.max(), loc.max()), # east
            max(la.max(), lac.max())  # north
        )
        lrll = ( # lower right longitude, latitude
            max(lo.max(), loc.max()), # east
            min(la.min(), lac.min())  # south
        )
        llll = ( # lower left  longitude, latitude
            min(lo.min(), loc.min()), # west
            min(la.min(), lac.min())  # south
        )
        ult = TILE3857.tile(*ulll, ZOOM) # upper left  tile
        urt = TILE3857.tile(*urll, ZOOM) # upper right tile
        lrt = TILE3857.tile(*lrll, ZOOM) # lower right tile
        llt = TILE3857.tile(*llll, ZOOM) # lower left  tile

        nx = lrt[0] - ult[0] + 1 # number of tiles in X
        ny = lrt[1] - ult[1] + 1 # number of tiles in Y
        ultb = TILE3857.bounds(*ult) # upper left  tile bounds ESPG:3857
        urtb = TILE3857.bounds(*urt) # upper right tile bounds ESPG:3857
        lrtb = TILE3857.bounds(*lrt) # lower right tile bounds ESPG:3857
        lltb = TILE3857.bounds(*llt) # lower left  tile bounds ESPG:3857

        # image size/resolution
        dpi    = 256
        scale  = 1 # multiplier to increase image size
        height = dpi*ny*scale
        width  = dpi*nx*scale

        fig = plt.figure(dpi=dpi, facecolor='none', edgecolor='none')
        fig.set_alpha(0)
        fig.set_figheight(height/dpi)
        fig.set_figwidth(width/dpi)

        ax = fig.add_axes([0., 0., 1., 1.], xticks=[], yticks=[])
        # ax.set_axis_off()
        ax.set_axis_on()


        # filled contour
        # tripcolor = ax.tripcolor(lo, la, nv, zeta, cmap='viridis')
        plotvar = temp
        tripcolor = ax.tripcolor(lo, la, nv, plotvar, cmap='viridis')

        ax.set_frame_on(False)
        ax.set_clip_on(False)
        ax.set_position([0, 0, 1, 1])

        ax.set_xlim(ultb[0], lrtb[2])
        ax.set_ylim(lrtb[1], ultb[3])

        # filename = 'fvcom-plot-%03d.png' % t # name by time index

        filename = 'fvcom-plot.png' 

        fig.savefig(filename, dpi=dpi, bbox_inches='tight', pad_inches=0.0, transparent=True)

        fig.clear()
        plt.close(fig)

        # crop to the active data (remove blank space)
        if crop:
            with PIL.Image.open(filename) as im:
                zeros = PIL.Image.new('RGBA', im.size)
                im = PIL.Image.composite(im, zeros, im)
                bbox = im.getbbox()
                crop = im.crop(bbox)
                crop.save(filename, optimize=True)

import sys
for t in range(0, 1): # range of times to plot (time indices in file)
    plot(sys.argv[1], t)
    # e.g. python plot_fvcom.py nos.sfbofs.fields.f.2019121115.f006.nc 
