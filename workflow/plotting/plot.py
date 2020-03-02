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
__email__ = "Kenny Ells, Brian McKenna, Patrick Tripp"


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


def plot_png(source='dubai', target='figs'):
    '''Plot roms output and save to png'''

    data = None
    datadir = os.getenv('DATA')
    if source == 'liveocean':
        data = os.path.join(datadir, 'LiveOcean_output/f2019.11.06')
    elif source == 'dubai':
        data = os.path.join(datadir, 'dubai_his_arg.20191226')

    if not os.path.exists(target):
        os.mkdir(target)

    files = sorted(glob.glob(f'{data}/*.nc'))

    # Scalar variables
    vars_scalar = [
        'temp',
        'zeta'
    ]

    # TODO: Fix coordinate system for u, v (and other vector quantities?). They
    #       use Psi space, while scalar fields use Rho space. Two ways:
    #       (1) The way Brian showed me for the maracoos project
    #       (2) https://www.geosci-model-dev.net/12/3571/2019/gmd-12-3571-2019.html
    vars_vector = [
        'u',
        'v'
    ]
    for v in vars_scalar:
        for f in files:
            print('Plotting {}'.format(f))
            plot_roms(f, target, v)
            print('Finished {}'.format(f))


def extract_ncdata(ncfile: str, varname: str):
    return

def plot_roms(ncfile: str, target: str, varname: str, crop: bool = False, zoom: int = 8):
    ''''''

    crop = True

    EPSG3857 = pyproj.Proj('EPSG:3857')
    TILE3857 = tile.Tile3857()

    with netCDF4.Dataset(ncfile) as nc:

        # Extract spatial variables
        lon = nc.variables['lon_rho'][:]
        lat = nc.variables['lat_rho'][:]
        msk = nc.variables['mask_rho'][:]
        lo, la = EPSG3857(lon, lat)  # project EPSG:4326 to EPSG:3857 (web mercator)

        # Temporal
        time = nc.variables['ocean_time']
        time = netCDF4.num2date(time[:], units=time.units)

        # Data
        data = nc.variables[varname]
        d = data[:]

        # Image size based on tiles
        mla = la[msk == 0]  # masked lat
        mlo = lo[msk == 0]  # masked lon
        lrt = TILE3857.tile(mlo.max(), mla.min(), zoom)
        lrb = TILE3857.bounds(*lrt)
        ult = TILE3857.tile(mlo.min(), mla.max(), zoom)
        ulb = TILE3857.bounds(*ult)
        ntx = lrt[0] - ult[0] + 1  # number of tiles in x
        nty = lrt[1] - ult[1] + 1  # number of tiles in y

        # loop times in file
        for t in range(len(time)):

            d = d[t, :]  # select time

            # check for vertical coordinate
            if d.ndim > 2:
                d = d[-1, :]  # surface is last in ROMS

            # apply mask
            d = np.ma.masked_where(msk == 0, d)

            # pcolor uses surrounding points, if any are masked, mask this cell
            #   see https://matplotlib.org/api/_as_gen/matplotlib.pyplot.pcolor.html
            d[:-1, :] = np.ma.masked_where(msk[1:, :] == 0, d[:-1, :])
            d[:, :-1] = np.ma.masked_where(msk[:, 1:] == 0, d[:, :-1])

            # image size/resolution
            # dpi = 256
            # dpi = 96
            dpi = 128
            # dpi = 512   # suitable for screen and web
            height = nty * dpi
            width = ntx * dpi

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
            pcolor = ax.pcolor(lo, la, d, cmap=plt.get_cmap('coolwarm'), edgecolor='none', linewidth=0.00)

            # ax.set_frame_on(False)
            ax.set_frame_on(True)
            ax.set_clip_on(True)
            ax.set_position([0, 0, 1, 1])

            # set limits based on tiles
            # ax.set_xlim(ulb[0], lrb[2])
            # ax.set_ylim(lrb[1], ulb[3])

            # File output
            # LO and general ROMS 
            #           11111
            # 012345678901234
            # ocean_his_0001.nc
            # NOSOFS 

            # 0   1     2      3    4        5
            # nos.dbofs.fields.f008.20200210.t00z

            # /asdf/asdf/asdf/ocean_his_0001.nc
            # asdf asdf asdf ocean_his_0001.nc

            # Get the end and then minus 3 characters
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

            # filename = f'{target}/{origfile}_{varname}.png'
            filename = f'{target}/f{sequence}_{varname}.png'
            # fig.savefig(filename, dpi=dpi, bbox_inches='tight', pad_inches=0.0, transparent=False)
            # fig.savefig(filename, dpi=dpi, transparent=False)
            fig.savefig(filename, dpi=dpi, bbox_inches=None, pad_inches=0.1, transparent=True)

            plt.close(fig)

            if crop:
                with PIL.Image.open(filename) as im:
                    zeros = PIL.Image.new('RGBA', im.size)
                    im = PIL.Image.composite(im, zeros, im)
                    bbox = im.getbbox()
                    crop = im.crop(bbox)
                    crop.save(filename, optimize=True)


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
    plot_roms(ncfile, target, var)

    # source = f"/com/nos/plots/dbofs.20200210/f%03d_{var}.png"
    # target = f"/com/nos/plots/dbofs.20200210/{var}.mp4"
    # png_ffmpeg(source, target)
