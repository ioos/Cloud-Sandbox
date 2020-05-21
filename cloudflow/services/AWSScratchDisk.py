import logging
import subprocess
import time
import traceback
import json

import boto3
from botocore.exceptions import ClientError
from prefect.engine import signals

from cloudflow.services.ScratchDisk import ScratchDisk, readConfig

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)

class AWSScratchDisk(ScratchDisk):
    """ AWS implementation of scratch disk.

    """

    def __init__(self, config: str):

        self.mountname: str = None
        self.dnsname: str = None
        self.filesystemid: str = None
        self.status: str = 'uninitialized'
        self.mountpath: str = '/ptmp'  # default can be reset in create()

        self.provider: str = 'AWS'
        self.capacity: int = 1200   # The smallest is 1.2 TB

        cfDict = readConfig(config)
        self.tags = cfDict['tags']
        self.sg_ids = cfDict['sg_ids']
        self.subnet_id = cfDict['subnet_id']
        self.region = cfDict['region']

        return



    def create(self, mountpath: str = '/ptmp'):
        """ Create a new FSx scratch disk and mount it locally """

        self.mountpath = mountpath

        client = boto3.client('fsx', region_name=self.region)

        try:
            response = client.create_file_system(
                FileSystemType='LUSTRE',
                StorageCapacity=self.capacity,
                SubnetIds=[ self.subnet_id ],
                SecurityGroupIds=self.sg_ids,
                Tags=self.tags,
                LustreConfiguration={
                    #'WeeklyMaintenanceStartTime': '',
                    'DeploymentType': 'SCRATCH_2'
                }
            )
            self.status='creating'

        except ClientError as e:
            log.exception('ClientError exception in createCluster' + str(e))
            raise Exception() from e
        
        '''
              'FileSystem': {
                  FileSystemId': 'string',
                  'DNSName': 'string',
                  'LustreConfiguration': {
                       'MountName': 'string'
        
        '''

        log.info("FSx drive creation in progress...")
        #print('Status: ', self.status)
        #print(json.dumps(response, indent=4))
        #print(response)
        self.filesystemid = response['FileSystem']['FileSystemId']
        self.dnsname = response['FileSystem']['DNSName']
        self.mountname = response['FileSystem']['LustreConfiguration']['MountName']

        # Now mount it
        self.__mount()
        #print(self.filesystemid)
        #print(self.dnsname)
        #print(self.mountname)


    def __mount(self):
        """ Mount the disk when it is ready """

        client = boto3.client('fsx', region_name=self.region)

        maxtries=20
        delay=30

        # Wait for it to be ready
        for x in range(maxtries):

            log.info("Waiting for FSx disk to become AVAILABLE ... this could take up to 10 minutes")

            if x == maxtries-1:
                log.exception('maxtries exceeded waiting for disk to become available ...')
                traceback.print_stack()
                raise signals.FAIL()

            response = client.describe_file_systems(FileSystemIds=[self.filesystemid])
            # 'Lifecycle': 'AVAILABLE' | 'CREATING' | 'FAILED' | 'DELETING' | 'MISCONFIGURED' | 'UPDATING',
            status = response['FileSystems'][0]['Lifecycle']
            #print(f'FSx status: {status}')

            # Mount it
            if status == 'AVAILABLE':
                log.info("FSx scratch disk is ready. Attempting to mount it locally...")
                try:
                    ''' sudo mount -t lustre -o noatime,flock fs-0efe931e2cc043a6d.fsx.us-east-1.amazonaws.com@tcp:/6i6xxbmv  /ptmp '''
                    result = subprocess.run(['sudo', 'mount', '-t', 'lustre', '-o', 'noatime,flock', 
                                            f'{self.dnsname}@tcp:/{self.mountname}', self.mountpath ],
                                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                    if result.returncode != 0:
                        log.exception('error attempting to mount scratch disk ...')
                        raise signals.FAIL()

                    # Chmod to make it writeable by all
                    result = subprocess.run(['sudo', 'chmod', '777', self.mountpath ],
                                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                    if result.returncode != 0:
                        log.exception('error attempting to chmod scratch disk ...')
                        raise signals.FAIL()

                except Exception as e:
                    log.exception('unable to mount scratch disk ...')
                    traceback.print_stack()
                    raise signals.FAIL()

                self.status='available'
                log.info(f"FSx scratch is mounted locally at {self.mountpath}")
                break
            else: 
                time.sleep(delay)

        return


    def delete(self):
        """ Delete this FSx disk """

        client = boto3.client('fsx', region_name=self.region)

        log.info('Unmounting FSx disk at {self.mountpath} ...')
        try:
            result = subprocess.run(['sudo', 'umount', '-f', self.mountpath ],
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            if result.returncode != 0:
                log.exception(f'error while unmounting scratch disk at {self.mountpath} ...')
        except Exception as e:
            log.exception('Exception while unmounting scratch disk at {self.mountpath} ...')
 
        try:
            response = client.delete_file_system(FileSystemId=self.filesystemid)
            if response['Lifecycle'] == 'DELETING':
                log.info(f'FSx disk {self.filesystemid} is DELETING')
                self.status='deleted'
            else:
                log.info(f'Something went wrong when deleting the FSx disk {self.filesystemid} ... manually check the status')
                self.status='error'

        except ClientError as e:
            log.exception('ClientError exception in AWSScratch.delete. ' + str(e))
            raise signals.FAIL()


    def remote_mount(self, hosts: list):
        """ Mount this FSx disk on remote hosts """

        for host in hosts:

            try:
                result = subprocess.run(['ssh', host, 'sudo', 'mount', '-t', 'lustre', '-o', 'noatime,flock', 
                                        f'{self.dnsname}@tcp:/{self.mountname}', self.mountpath ],
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                print(result.stdout)
                if result.returncode != 0:
                    log.exception('unable to mount scratch disk on host...', host)
                    raise signals.FAIL()

            except Exception as e:
                log.exception('unable to mount scratch disk on host...', host)
                traceback.print_stack()
                raise signals.FAIL()

        return


if __name__ == '__main__':
    pass
