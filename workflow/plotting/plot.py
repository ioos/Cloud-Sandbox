import glob
import os
import traceback
import subprocess

import pyproj
import cmocean
import netCDF4
import PIL.Image
import numpy as np
import matplotlib.pyplot as plt

# from plotting import tile
import tile

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

    #print(f"DEBUG: in png_ffmpeg. source: {source} target: {target}")

    #ff_str = f'ffmpeg -y -start_number 30 -r 1 -i {source} -vcodec libx264 -pix_fmt yuv420p -crf 25 {target}'
    #ff_str = f'ffmpeg -y -r 8 -i {source} -vcodec libx264 -pix_fmt yuv420p -crf 23 {target}'

    # TODO: ffmpeg is currently installed in user home directory. Install to standard location.
    # x264 codec enforces even dimensions
    # -vf "pad=ceil(iw/2)*2:ceil(ih/2)*2"
    try:
        proc = subprocess.run(['ffmpeg','-y','-r','8','-i',source,'-vcodec','libx264',\
                               '-pix_fmt','yuv420p','-crf','23','-vf', "pad=ceil(iw/2)*2:ceil(ih/2)*2", target], \
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


def plot_roms(ncfile: str, target: str, varname: str, crop: bool = False, zoom: int = 8):
    ''''''

    with netCDF4.Dataset(ncfile) as nc:

        # print(f'[plot.plot_roms] Reading file: {ncfile}')

        # Extract spatial variables
        lon = nc.variables['lon_rho'][:]
        lat = nc.variables['lat_rho'][:]
        msk = nc.variables['mask_rho'][:]
        lo,la = EPSG3857(lon,lat) # project EPSG:4326 to EPSG:3857 (web mercator)

        # Temporal
        time = nc.variables['ocean_time']
        time = netCDF4.num2date(time[:], units=time.units)

        # Data
        data = nc.variables[varname]
        d = data[:]

        # Image size based on tiles
        mla = la[msk == 0] # masked lat
        mlo = lo[msk == 0] # masked lon
        lrt = TILE3857.tile(mlo.max(), mla.min(), zoom)
        lrb = TILE3857.bounds(*lrt)
        ult = TILE3857.tile(mlo.min(), mla.max(), zoom)
        ulb = TILE3857.bounds(*ult)
        ntx = lrt[0] - ult[0] + 1 # number of tiles in x
        nty = lrt[1] - ult[1] + 1 # number of tiles in y

        # loop times in file
        for t in range(len(time)):

            # print(f'[plot.plot_roms] Looping times at t={t}\n')

            # select time
            d = d[t, :]

            # check for vertical coordinate
            if d.ndim > 2:
                d = d[-1,:] # surface is last in ROMS

            # apply mask
            d = np.ma.masked_where(msk == 0, d)

            # pcolor uses surrounding points, if any are masked, mask this cell
            # see https://matplotlib.org/api/_as_gen/matplotlib.pyplot.pcolor.html
            d[:-1,:] = np.ma.masked_where(msk[1:,:] == 0, d[:-1,:])
            d[:,:-1] = np.ma.masked_where(msk[:,1:] == 0, d[:,:-1])

            # image size/resolution
            #dpi = 256
            dpi = 96
            # dpi = 512   # suitable for screen and web
            height = nty * dpi
            width  = ntx * dpi

            fig = plt.figure(dpi=dpi, facecolor='#FFFFFF', edgecolor='w')
            #fig.set_alpha(1)
            fig.set_figheight(height/dpi)
            fig.set_figwidth(width/dpi)

            ax = fig.add_axes([0., 0., 1., 1.], xticks=[], yticks=[])
            #ax.set_axis_off()
            ax.set_axis_on()

            # pcolor
            #pcolor = ax.pcolor(lo, la, d, cmap=plt.get_cmap('viridis'), edgecolors='none', linewidth=0.05)
            pcolor = ax.pcolor(lo, la, d, cmap=plt.get_cmap('coolwarm'), edgecolor='none', linewidth=0.00)

            #ax.set_frame_on(False)
            ax.set_frame_on(True)
            ax.set_clip_on(True)
            ax.set_position([0, 0, 1, 1])

            # set limits based on tiles
            #ax.set_xlim(ulb[0], lrb[2])
            #ax.set_ylim(lrb[1], ulb[3])

            # File output
            # LO and general ROMS
            #           11111
            # 012345678901234
            # ocean_his_0001.nc
            # NOSOFS

            # 0   1     2      3    4        5
            # nos.dbofs.fields.f008.20200210.t00z

            #/asdf/asdf/asdf/ocean_his_0001.nc
            #asdf asdf asdf ocean_his_0001.nc

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

            #filename = f'{target}/{origfile}_{varname}.png'
            filename = f'{target}/f{sequence}_{varname}.png'
            #fig.savefig(filename, dpi=dpi, bbox_inches='tight', pad_inches=0.0, transparent=False)
            #fig.savefig(filename, dpi=dpi, transparent=False)
            if not os.path.exists(filename):
                fig.savefig(filename, dpi=dpi, bbox_inches=None, pad_inches=0.1, transparent=False)
                print(f'Created file:\n{filename}')

            plt.close(fig)

            if crop:
                with PIL.Image.open(filename) as im:
                    zeros = PIL.Image.new('RGBA', im.size)
                    im = PIL.Image.composite(im, zeros, im)
                    bbox = im.getbbox()
                    crop = im.crop(bbox)
                    crop.save(filename, optimize=True)

            return fig, ax


def make_png(varnames, files, target):
    for v in varnames:
        for f in  files:
            if not os.path.exists(target):
                os.mkdir(target)
                print(f'created target path: {target}')
            plot_roms(f, target, v)



############################# diff plot stuff #################################

def roms_extract(ncfile, varname='temp', spatial=True):

    with netCDF4.Dataset(ncfile) as nc:

        # Extract spatial variables
        lon = nc.variables['lon_rho'][:]
        lat = nc.variables['lat_rho'][:]
        lo, la = EPSG3857(lon, lat) # project EPSG:4326 to EPSG:3857 (web mercator)
        msk = nc.variables['mask_rho'][:]

        # Extract temporal variables
        time = nc.variables['ocean_time']
        time = netCDF4.num2date(time[:], units=time.units)

        # Extract field data
        data = nc.variables[varname]
        d = data[:]

        # Select time
        # NOTE: this takes first time step. was in a for loop before
        d = d[0, :]

        # Check for vertical coordinate
        if d.ndim > 2:
            d = d[-1,:] # surface is last in ROMS

        # Apply mask
        d = np.ma.masked_where(msk == 0, d)

        # pcolor uses surrounding points, if any are masked, mask this cell
        #   see https://matplotlib.org/api/_as_gen/matplotlib.pyplot.pcolor.html
        d[:-1,:] = np.ma.masked_where(msk[1:,:] == 0, d[:-1,:])
        d[:,:-1] = np.ma.masked_where(msk[:,1:] == 0, d[:,:-1])


        if not spatial:
            # Only return field data
            return d
        else:
            # Return spatial and field data
            return msk, lo, la, d

def roms_plot(mask, lon, lat, data, zoom=10):

    # Image size based on tiles
    mla = lat[mask == 0] # masked lat
    mlo = lon[mask == 0] # masked lon
    lrt = TILE3857.tile(mlo.max(), mla.min(), zoom)
    lrb = TILE3857.bounds(*lrt)
    ult = TILE3857.tile(mlo.min(), mla.max(), zoom)
    ulb = TILE3857.bounds(*ult)
    ntx = lrt[0] - ult[0] + 1 # number of tiles in x
    nty = lrt[1] - ult[1] + 1 # number of tiles in y

    # image size/resolution
    #dpi = 256
    dpi = 96
    #dpi = 512   # suitable for screen and web
    height = nty * dpi
    width  = ntx * dpi

    fig = plt.figure(dpi=dpi, facecolor='#FFFFFF', edgecolor='w')
    fig.set_alpha(1)
    fig.set_figheight(height/dpi)
    fig.set_figwidth(width/dpi)

    ax = fig.add_axes([0., 0., 1., 1.], xticks=[], yticks=[])
    ax.set_axis_off()
    #ax.set_axis_on()

    # pcolor
    #pcolor = ax.pcolor(lon, lat, data, cmap=plt.get_cmap('viridis'), edgecolors='none', linewidth=0.05)
    pcolor = ax.pcolor(lon, lat, data, cmap=plt.get_cmap('coolwarm'), edgecolor='none', linewidth=0.00)

    #ax.set_frame_on(False)
    ax.set_frame_on(True)
    ax.set_clip_on(True)
    ax.set_position([0, 0, 1, 1])

    # Save
    filename = 'diffplot.png'
    fig.savefig(filename, dpi=dpi, bbox_inches=None, pad_inches=0.1, transparent=False)


if __name__=='__main__':

    EPSG3857 = pyproj.Proj('EPSG:3857')
    TILE3857 = tile.Tile3857()

    f_aws = '/Users/kenny.ells/data/cbofs/AWS.cbofs.20191021/nos.cbofs.fields.f048.20191021.t00z.nc'
    f_noaa = '/Users/kenny.ells/data/cbofs/NOAA.cbofs.20191021/nos.cbofs.fields.f048.20191021.t00z.nc'

    # Get the spatial and field data for the first result
    msk, lo, la, d_aws = roms_extract(f_aws, varname='temp', spatial=True)

    # Get field data for second result
    d_noaa = roms_extract(f_noaa, varname='temp', spatial=False)

    # Subtract them
    d_diff = d_aws - d_noaa

    # Plot and save
    roms_plot(msk, lo, la, d_diff)
