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


class NFSScratchDisk(ScratchDisk):
    """ NFS implementation of scratch disk. Only manages the symbolic link to an already mounted NFS drive.
        Assumes all jobs will use the same scratch disk and path.
    """

    def __init__(self, config: str):
        """ Constructor: Currently has hardcoded paths. TODO: Refactor/parameterize settings."""

        # TODO: parameterize self.mount
        self.mount: str = '/mnt/efs/fs1/ptmp'
        self.status: str = 'uninitialized'
        self.mountpath: str = '/ptmp'  # default can be reset in create()

        # This is really provider agnostic
        self.provider: str = 'NFS'

        return



    def create(self, mountpath: str = '/ptmp'):
        """ The NFS disk is assumed to be mounted, just create a symlink

        Parameters
        ----------
        mountpath : str
            The path where the disk will be mounted. Default = /ptmp" (optional)
        """

        # TODO: maybe, create an additional EFS drive to use as /ptmp
        self.mountpath = mountpath

        # Now mount it
        self.__symlink()


    def __symlink(self):
        """ Make sure there is a symbolic link to /ptmp on local system """

        log.info("Creating symbolic link ...")

        # TODO: Check to make sure it is not in use
        subprocess.run(['sudo', 'rm', '-Rf', self.mountpath],
                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

        result = subprocess.run(['sudo', 'ln', '-s', self.mount, self.mountpath],
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

        if result.returncode != 0:
            print(result.stdout)
            log.exception('error attempting to mount scratch disk ...')
            raise signals.FAIL()

        self.status='available'

        return


    def delete(self):
        """ Do nothing for now"""
        return 


    def remote_mount(self, hosts: list):
        """ Create the symbolic link on each host

        Parameters
        ----------
        hosts : list of str
          The list of remote hosts
        """

        for host in hosts:
            result = subprocess.run(['ssh', host, 'sudo', 'rm', '-Rf', self.mountpath], 
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            if result.returncode != 0:
                print(result.stdout)
                log.warning(f'Unable to remove {mountpath} on {host}')

            try:
                result = subprocess.run(['ssh', host, 'sudo', 'ln', '-s', self.mount, self.mountpath],
                                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

                if result.returncode != 0:
                    print(result.stdout)
                    log.exception(f'Unable to mount scratch disk on {host}')
                    raise signals.FAIL()

            except Exception as e:
                log.exception(f'Unable to mount scratch disk on {host}')
                traceback.print_stack()
                raise signals.FAIL()
        return


if __name__ == '__main__':
    pass
