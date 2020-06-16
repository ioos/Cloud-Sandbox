#!/usr/bin/python3
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
from cloudflow.services.FSxScratchDisk import FSxScratchDisk

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)


def create_delete():
    config="/home/centos/Cloud-Sandbox/cloudflow/cluster/configs/nosofs.config"
    fsx = FSxScratchDisk(config)
    fsx.create('/ptmp')
    print("FSx disk was created and mounted locally")
    fsx.delete()


def main():
    #create_delete()
    mountpath = '/ptmp'
    result = subprocess.run(['sudo', 'rm', '-Rf', mountpath], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    #if result.returncode != 0:
    print(result.stdout)

    result = subprocess.run(['sudo', 'mkdir', '-p', mountpath], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout)


    return



if __name__ == '__main__':
    main()
