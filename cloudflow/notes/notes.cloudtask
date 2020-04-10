'''
A interface signature for cloud Task for prefect perhaps
Would like this to be able to run in parallel
Dask - supported by Prefect
DistributedPython
map/reduce
Dask example from: https://docs.dask.org/en/latest/setup/hpc.html
mpirun --np 4 dask-mpi --scheduler-file /home/$USER/scheduler.json

Amazon Elastic MapReduce (EMR) is a web service for creating a cloud-hosted Hadoop cluster.

'''

from prefect import Task

class CloudTask(Task):

  def run(self):
    print("... CloudTask.run stub")




def cloudTask ( scriptname, **kwargs) :
  print('... cloudTask stub')
  return



''' Data Access APIs
from: https://docs.dask.org/en/latest/setup/cloud.html
s3fs for Amazon’s S3
gcsfs for Google’s GCS
adlfs for Microsoft’s ADL

Dask Cluster Options
Manual setup: https://docs.dask.org/en/latest/setup/cli.html
SSH: https://docs.dask.org/en/latest/setup/ssh.html
HPC: https://docs.dask.org/en/latest/setup/hpc.html
YARN: https://yarn.dask.org/en/latest/
Python API: https://docs.dask.org/en/latest/setup/python-advanced.html
Cloud: https://cloudprovider.dask.org/en/latest/

'''
