""" Abstract base class for Job """
from abc import ABC, abstractmethod
import json

__copyright__ = "Copyright © 2023 RPS Group, Inc. All rights reserved."
__license__ = "BSD 3-Clause"


debug = False


class Job(ABC):
    """ Abstract base class for types of Job

    Attributes
    ----------
    configfile : str
    jobtype : str
    CDATE : str
    HH : str
    OFS : str
    OUTDIR : str
    INDIR : str
    NPROCS : int
    settings : dict
    VARS : list
    FSPEC : str

    """

    @abstractmethod
    def __init__(self):
        """ Constructor """

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



    def readConfig(self, configfile):
        """ reads the JSON file into a dictionary

        Parameters
        ----------
        configfile : str
            A JSON configuration file containing the required parameters for this class.

        """

        with open(configfile, 'r') as cf:
            cfDict = json.load(cf)

        if debug:
            print(json.dumps(cfDict, indent=4))
            print(str(cfDict))

        return cfDict

    ########################################################################

    @abstractmethod
    def parseConfig(self, cfDict) :
        pass


if __name__ == '__main__':
    pass
