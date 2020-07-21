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

from cloudflow.services import ScratchDisk
#from cloudflow.services.ScratchDisk import ScratchDisk, readConfig
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


def test_locks():
    mountpath = '/ptmp'

    print("creating lockfile")
    mylock = ScratchDisk.addlock(mountpath)
    os.scandir(mountpath)
    print("sleeping 10 ... ")
    time.sleep(10)

    print("has locks ?")
    print(ScratchDisk.haslocks(mountpath))

    print("removing lockfile")
    ScratchDisk.removelock(mountpath, mylock)
    os.scandir(mountpath)
    print("sleeping 10 ... ")
    time.sleep(10)

    print("has locks ?")
    print(ScratchDisk.haslocks(mountpath))



def test_locks2():
    mountpath = '/ptmp'

    print('acquiring lock')
    ScratchDisk.__acquire(mountpath)

    print('sleeping for 30 seconds with lock')
    time.sleep(30)

    print('releasing lock')
    ScratchDisk.__release(mountpath)
   

def main():
    test_locks()
    
    #test_locks2()

if __name__ == '__main__':
    main()

