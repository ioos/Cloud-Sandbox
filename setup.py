from setuptools import setup, find_packages
#__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
#__license__ = "BSD 3-Clause"


# setup cloud-workflow package
setup(name="cloudflow",
    version='1.3.2',
    description='Workflows for cloud based numerical weather prediction',
    url='https://github.com/asascience/Cloud-Sandbox',
    author='RPS North America',
    license="LICENSE.txt",
    setup_requires=['setuptools_scm'],
    packages=[ 'cloudflow/cluster', 'cloudflow/job',
               'cloudflow/plotting', 'cloudflow/services', 'cloudflow/utils',
               'cloudflow/workflows'
             ],
    package_data={
      '' : [ '*.sh' ],
      'cloudflow/job' : [ 'templates/*.in', 'jobs/*' ],
      'cloudflow/cluster' : [ 'configs/*' ],
      'cloudflow/workflows' : [ 'scripts/*' ]
      },
    #include_package_data=True,
    # DOESNT WORK data_files=[('configs', ['cloudflow/configs/*.config']),
    # DOESNT WORK ('jobs', ['cloudflow/jobs/*'])],
    install_requires=[
        'boto3',
        'prefect',
        'dask',
        'distributed',
        'Pillow',
        'matplotlib',
        'netCDF4',
        'numpy',
        'pyproj==2.6',
        'plotting']
     )
