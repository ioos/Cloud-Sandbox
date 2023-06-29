""" Plotting routines for FVCOM forecasts """
import os
import sys
import traceback

import PIL.Image
import matplotlib.pyplot as plt
import netCDF4
import numpy as np
import pyproj

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.plotting import tile
from cloudflow.plotting import shared

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


# This is a fix for matplotlib OSX thread issue
plt.switch_backend('Agg')

EPSG3857 = pyproj.Proj('EPSG:3857')
TILE3857 = tile.Tile3857()

debug = False

def make_png(varnames, files, target):
    """

    Parameters
    ----------
    varnames : list of str
        List of variables to plot

    files : list of str
        List of files to create plots from

    target : str
        Output directory for plots
    """
    for v in varnames:
        for f in  files:
            if not os.path.exists(target):
                os.mkdir(target)
                print(f'created target path: {target}')
            plot(f, target, v)
    return


def get_vmin_vmax(ncfile1_base: str, ncfile1_exp: str, varname: str) -> float:
    """ use this to set the vmin and vmax for a series of diff plots with uniform scales
        use a pair of files that are late in the sequence """

    print(f"DEBUG: in get_vmin_vmax: {ncfile1_base} {ncfile1_exp} {varname}")

    vmin=-1.0
    vmax=1.0

    d1_base = extract_ncdata(ncfile1_base, varname)
    d1_exp  = extract_ncdata(ncfile1_exp, varname)
    d1 = d1_base - d1_exp
    dmax1 = np.amax(d1)
    dmin1 = np.amin(d1)
    vmax = max(abs(dmax1),abs(dmin1))
    vmin = -vmax

    return vmin, vmax


# FVCOM
def extract_ncdata(ncfile: str, varname: str):

    #for t in range(0, 1): # range of times to plot (time indices in file)
    # plot(sys.argv[1], t)

    timestp = 0

    with netCDF4.Dataset(ncfile) as nc:

        # 3D variable
        #u = nc.variables['u'][t,0,:]  # sfc is first vertical level
        #v = nc.variables['v'][t,0,:]
        # temp(time, siglay, node)
        #temp = nc.variables['temp'][t,0,:]

        # 2D (surface) variable
        #zeta = nc.variables['zeta'][t,:]

        vars2d = ["zeta", "short_wave", "net_heat_flux", "uwind_speed", "vwind_speed"]
        vars3d = ["temp","salinity","u","v"]

        if varname in vars2d:
          vardata = nc.variables[varname][timestp,:]
        elif varname in vars3d:
          vardata = nc.variables[varname][timestp,0,:]   # sfc
        else:
          print('Unsupported varname in extract_ncdata: ' + varname)
          traceback.print_stack()
          raise Exception()

        return vardata


# FVCOM
def get_projection(ncfile: str):
    """ returns lo,la,loc,lac """


    with netCDF4.Dataset(ncfile) as nc:

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

    #print(f"{lo},{la},{loc},{lat},{nv}")
    return lo,la,loc,lac,nv



# FVCOM
def plot_data(data, lo, la, loc, lac, nv, varname: str, outfile: str, colormap: str,
              crop: bool=True, zoom: int=8, diff: bool=False, vmin: float=-1.0, vmax: float=1.0):

    plt.rcParams.update({'font.size': 3})

    fg_color = 'white'
    bg_color = 'black'

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
    ult = TILE3857.tile(*ulll, zoom) # upper left  tile
    urt = TILE3857.tile(*urll, zoom) # upper right tile
    lrt = TILE3857.tile(*lrll, zoom) # lower right tile
    llt = TILE3857.tile(*llll, zoom) # lower left  tile

    nx = lrt[0] - ult[0] + 1 # number of tiles in X
    ny = lrt[1] - ult[1] + 1 # number of tiles in Y
    ultb = TILE3857.bounds(*ult) # upper left  tile bounds ESPG:3857
    urtb = TILE3857.bounds(*urt) # upper right tile bounds ESPG:3857
    lrtb = TILE3857.bounds(*lrt) # lower right tile bounds ESPG:3857
    lltb = TILE3857.bounds(*llt) # lower left  tile bounds ESPG:3857

    # image size/resolution
    dpi    = 384
    scale  = 1.0
    height = dpi * ny * scale
    width  = dpi * nx * scale

    #fig = plt.figure(dpi=dpi, facecolor='none', edgecolor='none')
    fig = plt.figure(dpi=dpi, facecolor='#000000', edgecolor='w')
    #fig.set_alpha(1)
    fig.set_figheight(height / dpi)
    fig.set_figwidth(width / dpi)

    ax = fig.add_axes([0., 0., 1.0, 1.0], xticks=[], yticks=[])
    ax.set_axis_off()

    if diff:
        #tripcolor = ax.tripcolor(lo, la, nv, data, cmap='coolwarm')
        tripcolor = ax.tripcolor(lo, la, nv, data, vmin=vmin, vmax=vmax, cmap=plt.get_cmap(colormap), edgecolor='none', linewidth=0.00)
    else:
        tripcolor = ax.tripcolor(lo, la, nv, data, cmap=colormap, edgecolor='none', linewidth=0.00)

    title = outfile.split("/")[-1].split(".")[0]
    ax.set_title(title, color=bg_color)

    #ax.set_clip_on(True)
    ax.set_clip_on(False)
    ax.set_frame_on(False)

    #ax.set_position([0, 0, 1, 1])

    ax.set_aspect(1.0)

    #print(f"vmin: {vmin}, vmax: {vmax}")
    cb = fig.colorbar(tripcolor, ax=ax, ticks=[vmin, 0, vmax], location='bottom',shrink=0.6, extend='neither')
    cb.ax.tick_params(axis='both', which='major', labelsize=3)
    cb.ax.tick_params(axis='both', which='minor', labelsize=3)

    ax.set_xlim(ultb[0], lrtb[2])
    ax.set_ylim(lrtb[1], ultb[3])

    #fig.savefig(outfile, dpi=dpi, bbox_inches='tight', pad_inches=0.0, transparent=True)
    #fig.savefig(outfile, dpi=dpi, pad_inches=0.0, transparent=False)
    fig.savefig(outfile,dpi=dpi,facecolor="grey", bbox_inches='tight', pad_inches=0.025, transparent=True)

    fig.clear()
    plt.close(fig)

    # crop to the active data (remove blank space)
    if crop:
        with PIL.Image.open(outfile) as im:
            zeros = PIL.Image.new('RGBA', im.size)
            im = PIL.Image.composite(im, zeros, im)
            bbox = im.getbbox()
            crop = im.crop(bbox)
            crop.save(outfile, optimize=True)

    print(f"Created plot: {outfile}")
    return

# FVCOM
def plot(ncfile: str, target: str, varname: str, crop: bool = False, zoom: int = 8):

    lo, la, loc, lac, nv = get_projection(ncfile)

    data = extract_ncdata(ncfile, varname)

    outfile = shared.set_filename(ncfile, varname, target)

    colormap = 'jet'  # temp

    plot_data(data, lo, la, loc, lac, nv, varname, outfile, colormap)

    return


# FVCOM
def plot_diff(ncfile1: str, ncfile2: str, target: str, varname: str,
              vmin: float=-1.0, vmax: float=1.0, crop: bool=False, zoom: int=8):
    """ given two input netcdf files, create a plot of ncfile1 - ncfile2 for specified variable """

    if debug:
        print(f"file1: {ncfile1}")
        print(f"file2: {ncfile2}")
        print(f"vmin, vmax: {vmin}, {vmax}")

    lo, la, loc, lac, nv = get_projection(ncfile1)

    data1 = extract_ncdata(ncfile1, varname)
    data2 = extract_ncdata(ncfile2, varname)

    # TODO: add error check, make sure the two plots can be compared
    data = data1 - data2

    outfile = shared.set_diff_filename(ncfile1, varname, target)

    colormap = 'seismic'  # temp

    plot_data(data, lo, la, loc, lac, nv, varname, outfile, colormap, diff=True, vmin=vmin, vmax=vmax)

    return



if __name__ == '__main__':
    # source = 'figs/temp/his_arg_temp_%04d.png'
    # target = 'figs/test_temp.mp4'
    # png_ffmpeg(source, target)
    #var = 'h'
    #ncfile = '/com/nos/leofs.20200309/nos.leofs.fields.f001.20200309.t00z.nc'
    #target = '/com/nos/plots/leofs.20200309'

    ncfile='/com/nos/negofs.20200312/nos.negofs.fields.f048.20200312.t03z.nc'
    ncfile_noaa='/com/nos-noaa/negofs.20200312/nos.negofs.fields.f048.20200312.t03z.nc'
    target = '/com/nos/plots/negofs.20200312'
    var = 'temp'

    if not os.path.exists(target):
        os.makedirs(target)

    vmin, vmax = get_vmin_vmax(ncfile_noaa, ncfile, var)
    #plot_diff(ncfile_noaa, ncfile, target, var, vmin=-0.1, vmax=0.1)
    plot_diff(ncfile_noaa, ncfile, target, var, vmin,  vmax)
    #plot(ncfile,target,var)
