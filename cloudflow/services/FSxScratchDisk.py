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


class FSxScratchDisk(ScratchDisk):
    """ AWS FSx for Lustre implementation of scratch disk.
        Can only have one at a time. Assumes all jobs will use the same scratch disk and path
    """

    ''' Note: df  /ptmp provides the following details:
        df /ptmp | grep -v 'Filesystem' | grep tcp | awk '{print $1}'
        10.0.0.5@tcp:/2y2xnbmv
    '''

    ''' TODO: Reuse the existing scratch disk if one exists 
        This will be needed if running multiple forecasts at once, otherwise make the ptmp parameter different
        Possible solution:
            Create a unique identifier for this instance : use a class attribute to store this
            Also place a file at /ptmp of this unique id e.g. user.{self.id}
            When done, remove the user.{self.id} file 
            If there are no other user.files then the scratch disk can be unmounted and deleted
    '''

    def __init__(self, config: str):
        """ Constructor """

        self.mountname: str = None
        self.dnsname: str = None
        self.filesystemid: str = None
        self.status: str = 'uninitialized'
        self.mountpath: str = '/ptmp'  # default can be reset in create()
        self.__lockfile: str = "something_unique"

        self.provider: str = 'AWS'
        self.capacity: int = 1200   # The smallest is 1.2 TB

        cfDict = readConfig(config)
        self.tags = cfDict['tags']
        self.sg_ids = cfDict['sg_ids']
        self.subnet_id = cfDict['subnet_id']
        self.region = cfDict['region']

        return



    def create(self, mountpath: str = '/ptmp'):
        """ Create a new FSx scratch disk and mount it locally 

        Parameters
        ----------
        mountpath : str
            The path where the disk will be mounted. Default = /ptmp" (optional)
        """

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
        self.filesystemid = response['FileSystem']['FileSystemId']
        self.dnsname = response['FileSystem']['DNSName']
        self.mountname = response['FileSystem']['LustreConfiguration']['MountName']

        # Now mount it
        self.__mount()


    def __mount(self):
        """ Mount the disk when it is ready """

        client = boto3.client('fsx', region_name=self.region)

        maxtries=15
        delay=60

        # Wait for it to be ready
        log.info("Waiting for FSx disk to become AVAILABLE ... ")
        log.info("... this usually takes about 6 minutes but could take up to 12 minutes")

        for x in range(maxtries):

            if x == maxtries-1:
                log.exception('maxtries exceeded waiting for disk to become available ...')
                raise signals.FAIL()

            response = client.describe_file_systems(FileSystemIds=[self.filesystemid])
            # 'Lifecycle': 'AVAILABLE' | 'CREATING' | 'FAILED' | 'DELETING' | 'MISCONFIGURED' | 'UPDATING',
            status = response['FileSystems'][0]['Lifecycle']

            # Mount it
            if status == 'AVAILABLE':
                log.info("FSx scratch disk is ready.")

                # TODO: Make sure we don't have another run using this. Finish implementing locks
                subprocess.run(['sudo', 'rm', '-Rf', self.mountpath], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                subprocess.run(['sudo', 'mkdir','-p', self.mountpath], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                try:
                    ''' sudo mount -t lustre -o noatime,flock fs-0efe931e2cc043a6d.fsx.us-east-1.amazonaws.com@tcp:/6i6xxbmv  /ptmp '''
                    log.info("Attempting to mount it locally...")
                    result = subprocess.run(['sudo', 'mount', '-t', 'lustre', '-o', 'noatime,flock', 
                                            f'{self.dnsname}@tcp:/{self.mountname}', self.mountpath ],
                                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                    if result.returncode != 0:
                        print(result.stdout)
                        log.exception('error attempting to mount scratch disk ...')
                        raise signals.FAIL()

                    # Chmod to make it writeable by all
                    log.info("Attempting to chmod FSx disk ...")
                    result = subprocess.run(['sudo', 'chmod', '777', self.mountpath ],
                                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                    if result.returncode != 0:
                        print(result.stdout)
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
                log.info(f"Waiting for FSx disk to become AVAILABLE ... {x}")
                time.sleep(delay)

        return


    def delete(self):
        """ Delete this FSx disk """
 
        client = boto3.client('fsx', region_name=self.region)
        
        log.info(f'Unmounting FSx disk at {self.mountpath} ...')
        try:
            result = subprocess.run(['sudo', 'umount', '-f', self.mountpath ],
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            if result.returncode != 0:
                print(result.stdout)
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
        """ Mount this FSx disk on remote hosts 

        Parameters
        ----------
        hosts : list of str
          The list of remote hosts
        """

        for host in hosts:
            try:
                result = subprocess.run(['ssh', host, 'sudo', 'mount', '-t', 'lustre', '-o', 'noatime,flock', 
                                        f'{self.dnsname}@tcp:/{self.mountname}', self.mountpath ],
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                if result.returncode != 0:
                    print(result.stdout)
                    log.exception('unable to mount scratch disk on host...', host)
                    raise signals.FAIL()
            except Exception as e:
                log.exception('unable to mount scratch disk on host...', host)
                traceback.print_stack()
                raise signals.FAIL()
        return


if __name__ == '__main__':
    pass
