import logging
import subprocess
import time
import traceback
import os
import sys

import boto3
from botocore.exceptions import ClientError
from prefect.engine import signals

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.services.ScratchDisk import ScratchDisk, readConfig
from cloudflow.services.AWSScratchDisk import AWSScratchDisk

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)



def main():

    config="/home/centos/Cloud-Sandbox/cloudflow/cluster/configs/nosofs.config"
    fsx = AWSScratchDisk(config)
    fsx.create('/ptmp')
    print("FSx disk was created and mounted locally")
    fsx.delete()
    
    return



if __name__ == '__main__':
    main()
