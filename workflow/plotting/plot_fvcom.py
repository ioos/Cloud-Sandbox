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

# TODO: Move to shared.py
def make_png(varnames, files, target):
    for v in varnames:
        for f in  files:
            if not os.path.exists(target):
                os.mkdir(target)
                print(f'created target path: {target}')
            plot(f, target, v)


# TODO: Move to shared.py
def set_filename(ncfile: str, target: str):
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


# TODO: Move to shared.py
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
    home = os.path.expanduser("~")
    ffmpeg = home + '/bin/ffmpeg'

    try:
        proc = subprocess.run([ffmpeg, '-y', '-r', '8', '-i', source, '-vcodec', 'libx264', \
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


# FVCOM 
def extract_ncdata(ncfile: str, varname: str):

        #for t in range(0, 1): # range of times to plot (time indices in file)
        # plot(sys.argv[1], t)

    timestp = 0

    with netCDF4.Dataset(ncfile) as nc:

        # get variable of interest here
        # 3D variable
        #u = nc.variables['u'][t,0,:]  # sfc is first vertical level
        #v = nc.variables['v'][t,0,:]
        # temp(time, siglay, node)
        d3dvar = nc.variables[varname][timestp,0,:]

        # 2D (surface) variable
        d2dvar = nc.variables[varname][timestp,:]


# FVCOM
def get_projection(ncfile: str):
    ''' returns lat and lon '''

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

    return lo,la,loc,lac



# FVCOM
def plot(ncfile1: str, target: str, varname: str, crop: bool = False, zoom: int = 8):
    return



# FVCOM
def plot_data(data, lo, la, loc, lac, varname: str, outfile: str, crop: bool = True, zoom: int = 8):

    TILE3857 = tile.Tile3857()

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
    dpi    = 128
    scale  = 1 # multiplier to increase image size
    height = dpi*ny*scale
    width  = dpi*nx*scale

    #fig = plt.figure(dpi=dpi, facecolor='none', edgecolor='none')
    fig = plt.figure(facecolor='#FFFFFF', edgecolor='w')
    #fig.set_alpha(0)
    fig.set_figheight(height/dpi)
    fig.set_figwidth(width/dpi)

    ax = fig.add_axes([0., 0., 1., 1.], xticks=[], yticks=[])
    # ax.set_axis_off()
    ax.set_axis_on()

    # filled contour
    # tripcolor = ax.tripcolor(lo, la, nv, zeta, cmap='viridis')
    #tripcolor = ax.tripcolor(lo, la, nv, data, cmap='viridis')
    pcolor = ax.pcolor(lo, la, data, cmap=plt.get_cmap('coolwarm'), edgecolor='none', linewidth=0.00)

    #ax.set_frame_on(False)
    #ax.set_clip_on(False)
    ax.set_frame_on(True)
    ax.set_clip_on(True)

    ax.set_position([0, 0, 1, 1])

    ax.set_xlim(ultb[0], lrtb[2])
    ax.set_ylim(lrtb[1], ultb[3])

    fig.savefig(outfile, dpi=dpi, bbox_inches='tight', pad_inches=0.0, transparent=True)

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



# TODO: swap varname and target, varname is an input, target is output folder
def plot_diff(ncfile1: str, ncfile2: str, target: str, varname: str, crop: bool = False, zoom: int = 8):
    ''' given two input netcdf files, create a plot of ncfile1 - ncfile2 for specified variable '''

    lo, la, loc, lac = proj_lolaloclac(ncfile1)

    data1 = extract_ncdata(ncfile1, varname)
    data2 = extract_ncdata(ncfile2, varname)

    # TODO: add error check, make sure the two plots can be compared
    data_diff = data1 - data2

    outfile = set_filename(ncfile: str, target: str):

    plot_data(data_diff, vaname, outfile)

    return



if __name__ == '__main__':
    # source = 'figs/temp/his_arg_temp_%04d.png'
    # target = 'figs/test_temp.mp4'
    # png_ffmpeg(source, target)
    var = 'temp'
    ncfile = '/com/nos/dbofs.20200210/nos.dbofs.fields.f002.20200210.t00z.nc'
    target = '/com/nos/plots/dbofs.20200210'
    # ncfile='/com/liveocean/f2020.02.13/ocean_his_0001.nc'
    # target='/com/liveocean/plots/f2020.02.13'
    # plot_roms(ncfile, target, var, True, 8)
    #plot_roms(ncfile, target, var)

    # source = f"/com/nos/plots/dbofs.20200210/f%03d_{var}.png"
    # target = f"/com/nos/plots/dbofs.20200210/{var}.mp4"
    # png_ffmpeg(source, target)
