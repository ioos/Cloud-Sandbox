from abc import ABC, abstractmethod
import json

__copyright__ = "Copyright © 2020 RPS Group. All rights reserved."
__license__ = "See LICENSE.txt"
__email__ = "patrick.tripp@rpsgroup.com"

debug = False

class Job(ABC):
    ''' This is an abstract base class for job classes
        It defines a generic interface to implement
    '''

    @abstractmethod
    def __init__(self):

        self.configfile = ''
        self.jobtype = ''
        self.CDATE = ''
        self.HH = ''
        self.OFS = ''
        self.OUTDIR = ''
        self.INDIR = ''
        self.NPROCS = 0
        self.settings = {}
        self.VARS = None
        self.FSPEC = None

    ########################################################################

    def readConfig(self, configfile):

        with open(configfile, 'r') as cf:
            cfDict = json.load(cf)

        if (debug):
            print(json.dumps(cfDict, indent=4))
            print(str(cfDict))

        return cfDict

    ########################################################################

    @abstractmethod
    def parseConfig(self, cfDict) :
        pass


if __name__ == '__main__':
    pass
