""" Plotting routines for ROMS forecasts """

import os
import sys

import PIL.Image
import matplotlib.pyplot as plt
import netCDF4
import numpy as np
import pyproj

# This is a fix for matplotlib OSX thread issue
plt.switch_backend('Agg')

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.plotting import tile
from cloudflow.plotting import shared

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


EPSG3857 = pyproj.Proj('EPSG:3857')
TILE3857 = tile.Tile3857()

debug = False

def make_png(varnames, files, target):
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


# ROMS
def extract_ncdata(ncfile: str, varname: str):

    with netCDF4.Dataset(ncfile) as nc:

        # extract mask
        msk = nc.variables['mask_rho'][:]

        # Extract field data
        data = nc.variables[varname]

        dvar = data[:]

    # Select time
    # NOTE: this takes first time step. was in a for loop before
    dvar = dvar[0, :]

        # Check for vertical coordinate
    if dvar.ndim > 2:
        dvar = dvar[-1,:] # surface is last in ROMS

    # Apply mask
    dvar = np.ma.masked_where(msk == 0, dvar)

    # pcolor uses surrounding points, if any are masked, mask this cell
    #   see https://matplotlib.org/api/_as_gen/matplotlib.pyplot.pcolor.html
    dvar[:-1,:] = np.ma.masked_where(msk[1:,:] == 0, dvar[:-1,:])
    dvar[:,:-1] = np.ma.masked_where(msk[:,1:] == 0, dvar[:,:-1])

    return dvar


# ROMS
def get_projection(ncfile: str):
    """ returns mask_rho and lat lon from netcdf file """

    with netCDF4.Dataset(ncfile) as nc:

        # Extract spatial variables
        lon = nc.variables['lon_rho'][:]
        lat = nc.variables['lat_rho'][:]
        lo, la = EPSG3857(lon, lat)       # project EPSG:4326 to EPSG:3857 (web mercator)

        msk = nc.variables['mask_rho'][:]

    # return msk and lat lon
    return msk, lo, la


# ROMS
def plot_data(data, msk, lo, la, varname: str, outfile: str, colormap: str,
              crop: bool=True, zoom: int=8, diff: bool=False, vmin: float=-1.0, vmax: float=1.0):

    plt.rcParams.update({'font.size': 3})

    fg_color = 'white'
    bg_color = 'black'

    # Image size based on tiles
    mla = la[msk == 0]  # masked lat
    mlo = lo[msk == 0]  # masked lon
    lrt = TILE3857.tile(mlo.max(), mla.min(), zoom)
    lrb = TILE3857.bounds(*lrt)
    ult = TILE3857.tile(mlo.min(), mla.max(), zoom)
    ulb = TILE3857.bounds(*ult)
    ntx = lrt[0] - ult[0] + 1  # number of tiles in x
    nty = lrt[1] - ult[1] + 1  # number of tiles in y

    # image size/resolution
    #dpi = 256
    # dpi = 96
    dpi = 512
    scale = 1.0
    #scale = 1.0
    # dpi = 512   # suitable for screen and web
    height = nty * dpi * scale
    width = ntx * dpi * scale

    # fig = plt.figure(dpi=dpi, facecolor='#FFFFFF', edgecolor='w')
    fig = plt.figure(dpi=dpi, facecolor='#000000', edgecolor='w')
    # fig.set_alpha(1)
    fig.set_figheight(height / dpi)
    fig.set_figwidth(width / dpi)

    #ax = fig.add_axes([0., 0., 1., 1.], xticks=[], yticks=[])
    ax = fig.add_axes([0., 0., 1.0, 1.0], xticks=[], yticks=[])
    ax.set_axis_off()
    #left = 0.05
    #bottom = 0.05
    #width = 0.9
    #height = 0.9
    #ax = fig.add_axes([left, bottom, width, height])

    if diff:
        #dmax = np.amax(data)
        #dmin = np.amin(data)
        #extent=max(abs(dmax),abs(dmin))
        #print(f"In plot_roms. var: {varname} dmax: {dmax} dmin: {dmin}")
        pcolor = ax.pcolormesh(lo, la, data, vmin=vmin, vmax=vmax, cmap=plt.get_cmap(colormap), edgecolor='none', linewidth=0.00)
    else:
        pcolor = ax.pcolormesh(lo, la, data, cmap=plt.get_cmap(colormap), edgecolor='none', linewidth=0.00)

    title = outfile.split("/")[-1].split(".")[0]
    ax.set_title(title, color=bg_color)

    #ax.patch.set_facecolor(bg_color)
    # set tick and ticklabel color
    #ax.axes.tick_params(color=fg_color, labelcolor=fg_color)
    #ax.tick_params(axis='both', which='major', labelsize=10)
    #ax.tick_params(axis='both', which='minor', labelsize=12)

    #set_aspect

    ax.set_clip_on(True)
    ax.set_frame_on(False)

    #ax.set_position([0, 0, 1, 1])

    ax.set_aspect(1.0)

    #plt.subplots_adjust(left=0.1, right=0.9, top=0.9, bottom=0.1)

    #left = 0.05
    #bottom = 0.05
    #width = 0.9
    #height = 0.9
    #ax = fig.add_axes([left, bottom, width, height])

    #cb = fig.colorbar(pcolor, ax=ax, ticks=[vmin, vmin/2, 0, vmax/2, vmax], location='bottom',shrink=0.9, extend='both')
    cb = fig.colorbar(pcolor, ax=ax, ticks=[vmin, 0, vmax], location='bottom',shrink=0.7, extend='neither')
    #cb = fig.colorbar(pcolor, ax=ax, location='bottom')


    # set colorbar tick color
    #cb.ax.yaxis.set_tick_params(color=fg_color)

    cb.ax.tick_params(axis='both', which='major', labelsize=3)
    cb.ax.tick_params(axis='both', which='minor', labelsize=3)

    # set colorbar edgecolor
    #cb.outline.set_edgecolor(fg_color)

    # set colorbar ticklabels
    #plt.setp(plt.getp(cb.ax.axes, 'xticklabels'), color=fg_color)

    # fig.savefig(filename, dpi=dpi, bbox_inches='tight', pad_inches=0.0, transparent=False)
    # fig.savefig(filename, dpi=dpi, transparent=False)
    #fig.savefig(outfile, facecolor="black", dpi=dpi, bbox_inches=None, pad_inches=0.1, transparent=True)
    #fig.savefig(outfile, facecolor="grey", dpi=dpi, bbox_inches=None, pad_inches=0.1, transparent=True)
    fig.savefig(outfile,dpi=dpi,facecolor="grey", bbox_inches='tight', pad_inches=0.025, transparent=True)

    fig.clear()
    plt.close(fig)

    if crop:
        with PIL.Image.open(outfile) as im:
            zeros = PIL.Image.new('RGBA', im.size)
            im = PIL.Image.composite(im, zeros, im)
            bbox = im.getbbox()
            crop = im.crop(bbox)
            crop.save(outfile, optimize=True)

    print(f"Created plot: {outfile}")
    return

# ROMS
def plot(ncfile: str, target: str, varname: str, crop: bool = False, zoom: int = 8):

    """ given two input netcdf files, create a plot of ncfile1 - ncfile2 for specified variable """

    mask, lo, la = get_projection(ncfile)

    data = extract_ncdata(ncfile, varname)

    outfile = shared.set_filename(ncfile, varname, target)

    colormap = 'jet'  # temp
    plot_data(data, mask, lo, la, varname, outfile, colormap)

    return


# ROMS
def plot_diff(ncfile1: str, ncfile2: str, target: str, varname: str,
              vmin: float=-1.0, vmax: float=1.0, crop: bool=False, zoom: int=8):
    """ given two input netcdf files, create a plot of ncfile1 - ncfile2 for specified variable """


    if debug:
        print(f"file1: {ncfile1}")
        print(f"file2: {ncfile2}")
        print(f"vmin, vmax: {vmin}, {vmax}")

    mask, lo, la = get_projection(ncfile1)

    data1 = extract_ncdata(ncfile1, varname)
    data2 = extract_ncdata(ncfile2, varname)

    # TODO: add error check, make sure the two plots can be compared
    data = data1 - data2

    outfile = shared.set_diff_filename(ncfile1, varname, target)

    colormap = 'seismic'  # temp

    plot_data(data, mask, lo, la, varname, outfile, colormap, diff=True, vmin=vmin, vmax=vmax)

    return


if __name__ == '__main__':

    var = 'temp'
    # alkalinity
    # salt
    # oxygen

    target = '/save/ec2-user'

    FHR="07"
    myfcst='/com/ec2-user/LO_roms/cas6_traps2_x2b/f2017.06.01'
    ncfile = f'{myfcst}/ocean_his_00{FHR}.nc'

    otherfcst='/com/ec2-user/apogee/f2017.06.01'
    ncfile_noaa = f'{otherfcst}/ocean_his_00{FHR}.nc'

    if not os.path.exists(target):
        os.makedirs(target)

    # plot_roms(ncfile, target, var, True, 8)
    # plot(ncfile, target, var)

    plot_diff(ncfile_noaa, ncfile, target, var, vmin=-0.5, vmax=0.5)

    # source = f"/com/nos/plots/dbofs.20200210/f%03d_{var}.png"
    # target = f"/com/nos/plots/dbofs.20200210/{var}.mp4"
    # png_ffmpeg(source, target)
