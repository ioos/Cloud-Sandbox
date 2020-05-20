from abc import ABC, abstractmethod
import json

__copyright__ = "Copyright © 2020 RPS Group, Inc. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

debug = False

class ScratchDisk(ABC):
    """ Abstract base class for scratch disk.

    Abstract Methods
    ----------------


    """

    def __init__(self):
        provider: str = None
        status: str = None
        pass

    @abstractmethod
    def create(self):
        pass

    @abstractmethod
    def delete(self):
        pass

    @abstractmethod
    def remote_mount(self, hosts: list):
        pass


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
