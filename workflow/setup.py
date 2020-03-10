from setuptools import setup

# setup plotting
setup(name="plotting",
      version='0.3.0',
      description='Plotting for ROMS',
      url='https://github.com/asascience/Cloud-Sandbox/python/plotting',
      author='RPS North America',
      author_email='rpsgroup.com',
      packages=['plotting'],
      install_requires=[
          'plotting',
          'pyproj',
          'cmocean',
          'numpy',
          'matplotlib',
          'netCDF4',
          'Pillow']
      )

# setup cluster
# setup(name="pyclusterwf",
#      version='0.1b1',
#      description='Cloud cluster classes',
#      url='https://github.com/asascience/Cloud-Sandbox/python',
#      author='RPS North America',
#      author_email='rpsgroup.com',
#      packages=['cluster','job','services','workflows','utils'],
#      install_requires=[
#        'boto3',
#        'prefect']
#     )
# job
# workflows
# services
