import logging
import subprocess
import time
import traceback

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
        mountname: str = None
        dnsname: str = None
        filesystemid: str = None
        status: str = 'uninitialized'

        provider: str = 'AWS'
        capacity: int = 1.2   # The smallest is 1.2 TB

        cfDict = readConfig(config)
        self.tags = cfDict['tags']
        self.sg_ids = cfDict['sg_ids']
        self.subnet_id = cfDict['subnet_id']
        pass


    def create(self, mountpath: str = '/ptmp'):
        client = boto3.client('fsx')

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
        finally:
            self.status='error'

        '''
              'FileSystem': {
                  FileSystemId': 'string',
                  'DNSName': 'string',
                  'LustreConfiguration': {
                       'MountName': 'string'
        
        '''
        self.filesystemid = response.FileSystem.FileSystemId
        self.dnsname = response.FileSystem.DNSName
        self.mountname = response.FileSystem.LustreConfiguration.MountName

        # Now mount it
        self.__mount(mountpath)


    def __mount(self, mountpath: str = '/ptmp' ):
        """ Mount the disk when it is ready """
        # Wait for it to be ready

        client = boto3.client('fsx')

        maxtries=12
        delay=10

        for x in range(maxtries):

            if x == maxtries:
                log.exception('maxtries exceeded waiting for disk to become available ...')
                traceback.print_stack()
                raise signals.FAIL()

            response = client.describe_file_systems(FileSystemIds=[self.filesystemid])
            # 'Lifecycle': 'AVAILABLE' | 'CREATING' | 'FAILED' | 'DELETING' | 'MISCONFIGURED' | 'UPDATING',
            status = response.FileSystems.Lifecycle
            print(f'FSx status: {status}')
            if status == 'AVAILABLE':

                try:
                    ''' sudo mount -t lustre -o noatime,flock fs-0efe931e2cc043a6d.fsx.us-east-1.amazonaws.com@tcp:/ 6i6xxbmv  /ptmp '''
                    result = subprocess.run(['sudo', 'mount', '-t', 'lustre', '-o', 'noatime,flock', f'{self.dnsname}@tcp:/', self.mountname, mountpath ],
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True, text=True)
                    print(result.stdout)
                    if result.returncode != 0:
                        log.exception('unable to mount scratch disk ...')
                        traceback.print_stack()
                        raise signals.FAIL()
                except Exception as e:
                    log.exception('unable to mount scratch disk ...')
                    traceback.print_stack()
                    raise signals.FAIL()

                self.status='available'
                break
            time.sleep(delay)

        return


    def delete(self):
        client = boto3.client('fsx')

        # TODO: add error checking, try block
        response = client.delete_file_system(
            FileSystemId=self.filesystemid
        )


    def remote_mount(self, hosts: list):
        pass


if __name__ == '__main__':
    pass