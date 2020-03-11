import glob
import os
import traceback
import subprocess

import pyproj
import netCDF4
import PIL.Image
import numpy as np
import matplotlib.pyplot as plt

from plotting import tile

__copyright__ = "Copyright © 2020 RPS Group. All rights reserved."
__license__ = "See LICENSE.txt"
__author__ = "Kenny Ells, Brian McKenna, Patrick Tripp"

def make_png(varnames, files, target):
    for v in varnames:
        for f in  files:
            if not os.path.exists(target):
                os.mkdir(target)
                print(f'created target path: {target}')
            plot(f, target, v)


def set_filename(ncfile: str, varname: str, target: str):
    ''' create a standard named output filename to more easily make animations from plots'''

    origfile = ncfile.split('/')[-1][:-3]

    prefix = origfile[0:3]
    if prefix == 'nos':
        sequence = origfile.split('.')[3][1:4]
    else:
        # 012345678
        # ocean_his
        prefix = origfile[0:9]
        if prefix == 'ocean_his':
            sequence = origfile[11:14]

    filename = f'{target}/f{sequence}_{varname}.png'
    return filename


def png_ffmpeg(source, target):
    '''Make a movie from a set of sequential png files

    Parameters
    ----------
    source : string
        Path to sequentially named image files
        Example: '/path/to/images/prefix_%04d_varname.png'
    target : string
        Path to location to store output video file
        Example: '/path/to/output/prefix_varname.mp4'
    '''

    # Add exception if there are no files found for source

    # print(f"DEBUG: in png_ffmpeg. source: {source} target: {target}")

    # ff_str = f'ffmpeg -y -start_number 30 -r 1 -i {source} -vcodec libx264 -pix_fmt yuv420p -crf 25 {target}'
    # ff_str = f'ffmpeg -y -r 8 -i {source} -vcodec libx264 -pix_fmt yuv420p -crf 23 {target}'

    # ffmpeg is currently installed in user home directory. Install to standard location, or someplace in PATH envvar
    # x264 codec enforces even dimensions
    # -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2"

    proc = None
    #home = os.path.expanduser("~")
    #ffmpeg = home + '/bin/ffmpeg'

    try:
        proc = subprocess.run(['ffmpeg', '-y', '-r', '8', '-i', source, '-vcodec', 'libx264', \
                               '-pix_fmt', 'yuv420p', '-crf', '23', '-vf', "pad=ceil(iw/2)*2:ceil(ih/2)*2", target], \
                              stderr=subprocess.STDOUT)
        assert proc.returncode == 0
        print(f'Created animation: {target}')
    except AssertionError as e:
        print(f'Creating animation failed for {target}. Return code: {proc.returncode}')
        traceback.print_stack()
        raise Exception(e)
    except Exception as e:
        print('Exception from ffmpeg', e)
        traceback.print_stack()
        raise Exception(e)




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

   

def get_projection(ncfile: str):
    ''' returns mask_rho and lat lon from netcdf file '''

    EPSG3857 = pyproj.Proj('EPSG:3857')

    with netCDF4.Dataset(ncfile) as nc:

        # Extract spatial variables
        lon = nc.variables['lon_rho'][:]
        lat = nc.variables['lat_rho'][:]
        lo, la = EPSG3857(lon, lat)       # project EPSG:4326 to EPSG:3857 (web mercator)

        msk = nc.variables['mask_rho'][:]
    
    # return msk and lat lon
    return msk, lo, la


def plot_data(data, msk, lo, la, varname: str, outfile: str, colormap: str, crop: bool = True, zoom: int = 8):
    ''''''

    #crop = True

    TILE3857 = tile.Tile3857()

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
    dpi = 128
    scale = 2.0
    #scale = 1.0
    # dpi = 512   # suitable for screen and web
    height = nty * dpi * scale
    width = ntx * dpi * scale

    # fig = plt.figure(dpi=dpi, facecolor='#FFFFFF', edgecolor='w')
    fig = plt.figure(facecolor='#FFFFFF', edgecolor='w')
    # fig.set_alpha(1)
    fig.set_figheight(height / dpi)
    fig.set_figwidth(width / dpi)

    ax = fig.add_axes([0., 0., 1., 1.], xticks=[], yticks=[])
    ax.set_axis_off()
    # ax.set_axis_on()

    # pcolor
    # pcolor = ax.pcolor(lo, la, d, cmap=plt.get_cmap('viridis'), edgecolors='none', linewidth=0.05)
    pcolor = ax.pcolor(lo, la, data, cmap=plt.get_cmap(colormap), edgecolor='none', linewidth=0.00)

            # ax.set_frame_on(False)
    ax.set_frame_on(True)
    ax.set_clip_on(True)
    ax.set_position([0, 0, 1, 1])

    # fig.savefig(filename, dpi=dpi, bbox_inches='tight', pad_inches=0.0, transparent=False)
    # fig.savefig(filename, dpi=dpi, transparent=False)
    fig.savefig(outfile, dpi=dpi, bbox_inches=None, pad_inches=0.1, transparent=True)

    plt.close(fig)

    if crop:
        with PIL.Image.open(outfile) as im:
            zeros = PIL.Image.new('RGBA', im.size)
            im = PIL.Image.composite(im, zeros, im)
            bbox = im.getbbox()
            crop = im.crop(bbox)
            crop.save(outfile, optimize=True)

    return


def plot(ncfile: str, target: str, varname: str, crop: bool = False, zoom: int = 8):

    ''' given two input netcdf files, create a plot of ncfile1 - ncfile2 for specified variable '''

    mask, lo, la = get_projection(ncfile)

    data = extract_ncdata(ncfile, varname)

    outfile = set_filename(ncfile, varname, target)

    colormap = 'jet'  # temp
    plot_data(data, mask, lo, la, varname, outfile, colormap)

    return



def plot_diff(ncfile1: str, ncfile2: str, target: str, varname: str, crop: bool = False, zoom: int = 8):
    ''' given two input netcdf files, create a plot of ncfile1 - ncfile2 for specified variable '''

    mask, lo, la = get_projection(ncfile1)

    data1 = extract_ncdata(ncfile1, varname)
    data2 = extract_ncdata(ncfile2, varname)

    # TODO: add error check, make sure the two plots can be compared
    data_diff = data1 - data2

    outfile = set_filename(ncfile1, varname, target)

    colormap = 'seismic'  # temp
    plot_data(data_diff, mask, lo, la, varname, outfile, colormap)

    return



if __name__ == '__main__':
    # source = 'figs/temp/his_arg_temp_%04d.png'
    # target = 'figs/test_temp.mp4'
    # png_ffmpeg(source, target)
    var = 'temp'
    ncfile = '/com/nos/tbofs.20200310/nos.tbofs.fields.f048.20200310.t00z.nc'
    target = '/com/nos/plots/tbofs.20200310'

    if not os.path.exists(target):
        os.makedirs(target)

    # ncfile='/com/liveocean/f2020.02.13/ocean_his_0001.nc'
    # target='/com/liveocean/plots/f2020.02.13'
    # plot_roms(ncfile, target, var, True, 8)
    plot(ncfile, target, var)

    # source = f"/com/nos/plots/dbofs.20200210/f%03d_{var}.png"
    # target = f"/com/nos/plots/dbofs.20200210/{var}.mp4"
    # png_ffmpeg(source, target)
