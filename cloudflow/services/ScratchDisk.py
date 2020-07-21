from abc import ABC, abstractmethod
import subprocess
import json
import os
import uuid
import glob
import fcntl
import traceback
import time
from prefect.engine import signals


__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

debug = False

class ScratchDisk(ABC):
    """ Abstract base class for scratch disk. """

    def __init__(self):
        """ Constructor """
        provider: str = None
        status: str = None
        pass

    @abstractmethod
    def create(self):
        """ Create the scratch disk """
        pass

    @abstractmethod
    def delete(self):
        """ Delete the scratch disk """
        pass

    @abstractmethod
    def remote_mount(self, hosts: list):
        """ Mount the scratch disk on remote hosts 

        Parameters
        ----------
        hosts : list of str
          The list of remote hosts
        """
        pass


# The lock acquire and release are to help prevent race conditions, only once running process at a time 
# can access the locking mechansims
def __acquire(mountpath: str):
    tries=0
    maxtries=3
    #delay=0.1
    delay=2 
    timeout=1

    lockfile=f'{mountpath}/.lockctl'
    while tries < maxtries :
        if os.path.exists(lockfile):
            print(f'lock not acquired ... trying again in {delay} seconds')
            time.sleep(delay)
            tries += 1
            continue
        else:
           lock = open(lockfile, "w") 
           print('lock acquired ')
           lock.close()
           return
        
    print(f'ERROR: Unable to obtain lock on {mountpath}. You may need to delete it.')
    traceback.print_stack()
    raise signals.FAIL() 
    return

 
def __release(mountpath: str):
    lockfile=f'{mountpath}/.lockctl'

    try:
        os.remove(lockfile)
        print('lock released')
    except Exception as e:
        print(f'ERROR: error releasing lock {lockfile}')
        raise signals.FAIL()
    return


def addlock(mountpath: str) -> str:
    """ Place a file on the disk to act as a lock to prevent disk unmounting/deletion. """
    __acquire(mountpath)

    uid = uuid.uuid4()
    with open(f'{mountpath}/lock.{uid.hex}','w') as lock:
        lock.write(uid.hex)

    __release(mountpath)        
    return uid.hex


def removelock(mountpath: str, uid: str):
    """ Remove an existing lock file from the disk. """
    __acquire(mountpath)

    os.remove(f'{mountpath}/lock.{uid}')

    __release(mountpath)
    return


def haslocks(mountpath: str) -> bool:
    """ Test if any locks exist on the disk. """
    __acquire(mountpath)

    response = True
    if len(glob.glob(f'{mountpath}/lock.*')) == 0:
        response = False

    __release(mountpath)
    return response


def readConfig(configfile) -> dict:
    """ Reads a JSON configuration file into a dictionary.

    Parameters
    ----------
    configfile : str
      Full path and filename of a JSON configuration file for this cluster.

    Returns
    -------
    cfDict : dict
      Dictionary containing this cluster parameterized settings.
    """

    with open(configfile, 'r') as cf:
        cfDict = json.load(cf)

    if debug:
        print(json.dumps(cfDict, indent=4))
        print(str(cfDict))

    # Single responsibility says I should only read it here
    return cfDict


if __name__ == '__main__':
    pass
