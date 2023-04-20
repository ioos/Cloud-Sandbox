import logging
import subprocess
import time
import traceback
import json
import os
import re

import boto3
from botocore.exceptions import ClientError
from prefect.engine import signals

from cloudflow.services.ScratchDisk import ScratchDisk, readConfig
import cloudflow.services.ScratchDisk as ScratchDiskModule

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)


class NFSScratchDisk(ScratchDisk):
    """ NFS implementation of scratch disk. Only manages the symbolic link to an already mounted NFS drive.
        Assumes all jobs will use the same scratch disk and path.
    """

    def __init__(self, config: str):
        """ Constructor: Currently has hardcoded paths. TODO: Refactor/parameterize settings."""

        # TODO: parameterize self.mount, currently hardcoded
        self.mount: str = '/mnt/efs/fs1/ptmp'
        self.status: str = 'uninitialized'
        self.mountpath: str = '/ptmp'  # default can be reset in create()

        # This is really provider agnostic
        self.provider: str = 'NFS'

        return


    def _mountexists(self) -> bool:
        """ Check to see if a disk is already mounted at mountpath """
        # df /ptmp (EFS): fs-46891ac5.efs.us-east-1.amazonaws.com:/   /mnt/efs/fs1
        # df /ptmp (FSx): 10.0.0.5@tcp:/2y2xnbmv 
        if os.path.isdir(self.mountpath):
            result = subprocess.run(['df', '--output=source', self.mountpath], encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            source = result.stdout.split()[1]
            if re.search(".efs.", source) or re.search("@tcp:/", source):
                return True
            else: return False
        else:
            return False


    def create(self, mountpath: str = '/ptmp'):
        """ The NFS disk is assumed to be mounted, just create a symlink

        Parameters
        ----------
        mountpath : str
            The path where the disk will be mounted. Default = /ptmp" (optional)
        """

        self.lockid = ScratchDiskModule.addlock(mountpath)

        # TODO: maybe, create an additional EFS drive to use as /ptmp
        self.mountpath = mountpath

        if self._mountexists():
            log.info("Scratch disk already exists...")
            return

        elif ScratchDiskModule.get_lockcount(self.mountpath) == 1:
            # Mount does not exist, but another process might be creating it 
            # We just created a lock for this, so lock count must be == 1 if we are the only one starting it

            # Now mount it
            log.info("Creating symbolic link ...")

            # TODO: Check to make sure it is not in use
            subprocess.run(['sudo', 'rm', '-Rf', self.mountpath],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

            result = subprocess.run(['sudo', 'ln', '-s', self.mount, self.mountpath],
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

            if result.returncode != 0:
                print(result.stdout)
                log.exception(f'error attempting to create link to scratch disk ...')
                raise signals.FAIL()

            self.status='available'
        return


    def delete(self):
        """ Just remove the lock for this process """
        ScratchDiskModule.removelock(self.mountpath, self.lockid)
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
