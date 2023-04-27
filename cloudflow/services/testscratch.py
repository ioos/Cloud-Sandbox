#!/usr/bin/python3
import logging
import subprocess
import time
import traceback
import os
import sys
import uuid

import boto3
from botocore.exceptions import ClientError
from prefect.engine import signals

if os.path.abspath('..') not in sys.path:
    sys.path.append(os.path.abspath('..'))

from cloudflow.services import ScratchDisk
#from cloudflow.services.ScratchDisk import ScratchDisk, readConfig
from cloudflow.services.FSxScratchDisk import FSxScratchDisk

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


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
   

def test_utils():
    config='/home/centos/Cloud-Sandbox/cloudflow/cluster/configs/ioos.config'
    scratch = FSxScratchDisk(config)
    result = scratch._pathexists()
    print(f'pathexists: {result}')
    result = scratch._mountexists()
    print(f'mountexists: {result}')


def testbotofsx():

    client = boto3.client('fsx', region_name='us-east-1')
    filesystems = client.describe_file_systems()['FileSystems']
    # we can get mountname from df
    # search FileSystems list for mountname
    #mountname = response['FileSystem']['LustreConfiguration']['MountName']
      
    result = subprocess.run(['df', '--output=source', '/ptmp'], encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    dfmountname = result.stdout.split()[1].split('/')[1]
    dfmountname = 'garbage'
    index = 0
    for fs in filesystems:
        mountname = fs['LustreConfiguration']['MountName']
        if mountname == dfmountname:
            print('FOUND IT')
            filesystemid = fs['FileSystemId']
            dnsname = fs['DNSName']
            break
        else:
            index += 1
            if index == len(filesystems):
                print('ERROR: Unable to locate a matching FSx disk')
                raise Exception
            continue

    print(filesystemid) 
    print(dnsname)
    print(mountname)


def test_uuid():
    uid = uuid.uuid4()
    print(f'uid: {uid}')
    print(f'uid.hex: {uid.hex}')
    
    
def main():
    #test_locks()
    #test_locks2()
    #test_utils()
    #testbotofsx()
    test_uuid()

if __name__ == '__main__':
    main()

