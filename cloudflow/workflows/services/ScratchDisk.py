from abc import ABC, abstractmethod
import subprocess
import json
import os
import uuid
import glob
import fcntl
import traceback
import time
import logging
from prefect.engine import signals


__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


log = logging.getLogger('workflow')
log.setLevel(logging.DEBUG)

debug = False

_LOCKROOT='/tmp/mntlocks'

class ScratchDisk(ABC):
    """ Abstract base class for scratch disk. """

    def __init__(self):
        """ Constructor """
        provider: str = None
        status: str = None
        lockid: str = None
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
# There is still potential for a race condition here.
# If another process is blocking on entering the mutex to add a lock, another process that has the lock can still remove the disk
# TODO: possibly make __acquire non-blocking
def _acquire(mountpath: str):
    tries=0
    maxtries=3
    delay=0.1

    lockpath=f'{_LOCKROOT}{mountpath}'
    lockfile=f'{lockpath}/.lockctl'
    if not os.path.exists(lockpath):
       os.makedirs(lockpath)

    while tries < maxtries :
        # If lockfile exists, some other process is holding the lock
        if os.path.exists(lockfile):
            #print(f'lock not acquired ... trying again in {delay} seconds')
            time.sleep(delay)
            tries += 1
            continue
        else:
           lock = open(lockfile, "w") 
           #print('lock acquired ')
           lock.close()
           return
        
    log.exception(f'ERROR: Unable to obtain lock on {lockfile}. You may need to delete it.')
    traceback.print_stack()
    raise signals.FAIL() 
    return

 
def _release(mountpath: str):

    try:
        os.remove(f'{_LOCKROOT}{mountpath}/.lockctl')
        #print('lock released')
    except Exception as e:
        log.exception(f'ERROR: error releasing lock {_LOCKROOT}{mountpath}/.lockctl')
        raise signals.FAIL()
    return


# TODO: Should these be made class functions?
def addlock(mountpath: str) -> str:
    """ Place a file on the disk to act as a lock to prevent disk unmounting/deletion. """
    _acquire(mountpath)

    uid = uuid.uuid4()
    with open(f'{_LOCKROOT}{mountpath}/lock.{uid}','w') as lock:
        lock.write(str(uid))

    _release(mountpath)        
    return uid


def removelock(mountpath: str, uid: str):
    """ Remove an existing lock file from the disk. """
    _acquire(mountpath)

    log.debug(f'attempting to remove lock {_LOCKROOT}{mountpath}/lock.{uid}')
    os.remove(f'{_LOCKROOT}{mountpath}/lock.{uid}')

    _release(mountpath)
    return


def haslocks(mountpath: str) -> bool:
    """ Test if any locks exist on the disk. """
    _acquire(mountpath)

    response = True
    if len(glob.glob(f'{_LOCKROOT}{mountpath}/lock.*')) == 0:
        response = False
        log.debug(f'{_LOCKROOT}{mountpath} has zero locks')
    else: 
        log.debug(f'{_LOCKROOT}{mountpath} has one or more locks')

    _release(mountpath)
    return response


def get_lockcount(mountpath: str) -> int:
    """ How many processes are using this mount """
    _acquire(mountpath)

    count = len(glob.glob(f'{_LOCKROOT}{mountpath}/lock.*'))

    _release(mountpath)
    return count


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
