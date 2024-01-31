from setuptools import setup
#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


# setup plotting
setup(name="plotting",
      version='0.3.1',
      description='Plotting for ROMS',
      url='https://github.com/ioos/Cloud-Sandbox/python/plotting',
      author='RPS North America',
      author_email='rpsgroup.com',
      packages=['plotting'],
      install_requires=[
          'pyproj',
          'cmocean',
          'numpy',
          'matplotlib',
          'netCDF4',
          'dask',
          'distributed',
          'Pillow',
          'boto3',
          'cartopy',
          'xarray']
)
